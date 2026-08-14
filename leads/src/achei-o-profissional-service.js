import { UpstreamError, ValidationError } from "./errors.js";
import {
  extractEmbeddedProfessionals,
  extractFirstProfessionalId,
  extractHiddenNumberProfessionals,
  extractListingCards,
  extractNextPayloads,
  extractProfileLinks,
  parseWhatsAppPhone,
} from "./parser.js";

const DEFAULT_BASE_URL = "https://acheioprofissional.com.br";
const DEFAULT_CACHE_TTL_MS = 15 * 60 * 1_000;
const DEFAULT_TIMEOUT_MS = 20_000;
const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

function validateSlug(value, field) {
  if (typeof value !== "string" || !SLUG_PATTERN.test(value)) {
    throw new ValidationError(
      `${field} must be a lowercase URL slug containing only letters, numbers, and hyphens.`,
    );
  }
}

async function mapWithConcurrency(items, concurrency, callback) {
  const results = new Array(items.length);
  let nextIndex = 0;

  async function worker() {
    while (nextIndex < items.length) {
      const index = nextIndex;
      nextIndex += 1;
      results[index] = await callback(items[index], index);
    }
  }

  const workers = Array.from(
    { length: Math.min(concurrency, items.length) },
    () => worker(),
  );
  await Promise.all(workers);
  return results;
}

function recordKey(record) {
  return [record.name, record.city, record.state]
    .map((value) => String(value ?? "").trim().toLocaleLowerCase("pt-BR"))
    .join("|");
}

function recordQueues(records) {
  const queues = new Map();

  for (const record of records) {
    const key = recordKey(record);
    const queue = queues.get(key) ?? [];
    queue.push(record);
    queues.set(key, queue);
  }

  return queues;
}

function shiftMatching(queues, record) {
  const queue = queues.get(recordKey(record));
  return queue?.shift() ?? null;
}

function nameQueues(records) {
  const queues = new Map();

  for (const record of records) {
    const key = record.name.trim().toLocaleLowerCase("pt-BR");
    const queue = queues.get(key) ?? [];
    queue.push(record);
    queues.set(key, queue);
  }

  return queues;
}

function shiftByName(queues, name) {
  const key = name.trim().toLocaleLowerCase("pt-BR");
  return queues.get(key)?.shift() ?? null;
}

export class AcheiOProfissionalService {
  constructor({
    baseUrl = DEFAULT_BASE_URL,
    cacheTtlMs = DEFAULT_CACHE_TTL_MS,
    fetchImpl = globalThis.fetch,
    redirectConcurrency = 4,
    timeoutMs = DEFAULT_TIMEOUT_MS,
  } = {}) {
    if (typeof fetchImpl !== "function") {
      throw new TypeError("A fetch implementation is required.");
    }

    this.baseUrl = new URL(baseUrl);
    this.cacheTtlMs = cacheTtlMs;
    this.fetchImpl = fetchImpl;
    this.redirectConcurrency = redirectConcurrency;
    this.timeoutMs = timeoutMs;
    this.cache = new Map();
    this.inflight = new Map();
    this.phoneCache = new Map();
    this.profileIdCache = new Map();
  }

  buildListingUrl(category, city) {
    validateSlug(category, "category");
    validateSlug(city, "city");
    return new URL(`/${category}/${city}`, this.baseUrl);
  }

  async scrape(category, city) {
    const listingUrl = this.buildListingUrl(category, city);
    const cacheKey = listingUrl.href;
    const cached = this.cache.get(cacheKey);

    if (cached && cached.expiresAt > Date.now()) return cached.value;
    if (this.inflight.has(cacheKey)) return this.inflight.get(cacheKey);

    const request = this.scrapeListing(listingUrl)
      .then((value) => {
        this.cache.set(cacheKey, {
          expiresAt: Date.now() + this.cacheTtlMs,
          value,
        });
        return value;
      })
      .finally(() => this.inflight.delete(cacheKey));

    this.inflight.set(cacheKey, request);
    return request;
  }

  async scrapeListing(listingUrl) {
    const html = await this.fetchText(listingUrl);
    const payloads = extractNextPayloads(html);
    const embedded = extractEmbeddedProfessionals(payloads);
    const hidden = extractHiddenNumberProfessionals(payloads);
    const cards = extractListingCards(html);
    const profileLinks = extractProfileLinks(html);
    const embeddedQueues = recordQueues(embedded);
    const hiddenQueues = recordQueues(hidden);
    const usedEmbeddedIds = new Set();

    let visible;
    if (profileLinks.length > 0) {
      const embeddedByName = nameQueues(embedded);
      const hiddenByName = nameQueues(hidden);
      const cardsByName = nameQueues(cards);

      visible = profileLinks.map((link) => {
        const embeddedRecord = shiftByName(embeddedByName, link.name);
        if (embeddedRecord) usedEmbeddedIds.add(embeddedRecord.sourceId);

        const record =
          embeddedRecord ??
          shiftByName(hiddenByName, link.name) ??
          shiftByName(cardsByName, link.name);

        if (!record) {
          throw new UpstreamError(
            `Could not find listing data for ${link.name}.`,
          );
        }

        return { ...record, profileUrl: link.profileUrl };
      });
    } else {
      visible = cards.map((card) => {
        const embeddedRecord = shiftMatching(embeddedQueues, card);
        if (embeddedRecord) {
          usedEmbeddedIds.add(embeddedRecord.sourceId);
          return { ...card, ...embeddedRecord };
        }

        const hiddenRecord = shiftMatching(hiddenQueues, card);
        return { ...card, ...hiddenRecord };
      });
    }

    const resolvedVisible = await mapWithConcurrency(
      visible,
      this.redirectConcurrency,
      async (record) => {
        if (record.whatsapp) return record;

        const sourceId =
          record.sourceId ?? (await this.resolveProfileId(record.profileUrl));
        return {
          ...record,
          sourceId,
          whatsapp: await this.resolveHiddenPhone(
            { ...record, sourceId },
            listingUrl,
          ),
        };
      },
    );

    const remaining = embedded.filter(
      (record) => !usedEmbeddedIds.has(record.sourceId),
    );
    const professionals = [...resolvedVisible, ...remaining].map(
      ({ sourceId: _sourceId, profileUrl: _profileUrl, ...record }, index) => ({
        ...record,
        position: index + 1,
      }),
    );

    return {
      sourceUrl: listingUrl.href,
      count: professionals.length,
      professionals,
    };
  }

  async fetchText(url) {
    let response;

    try {
      response = await this.fetchImpl(url, {
        headers: {
          accept: "text/html,application/xhtml+xml",
          "user-agent":
            "AcheiOProfissionalDirectoryReader/1.0 (+public directory extraction)",
        },
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (error) {
      throw new UpstreamError(`Could not load ${url.href}.`, { cause: error });
    }

    if (!response.ok) {
      throw new UpstreamError(
        `Achei o Profissional returned HTTP ${response.status} for ${url.href}.`,
      );
    }

    return response.text();
  }

  async resolveHiddenPhone(record, listingUrl) {
    if (this.phoneCache.has(record.sourceId)) {
      return this.phoneCache.get(record.sourceId);
    }

    const clickUrl = new URL(`/api/click/${record.sourceId}`, this.baseUrl);
    clickUrl.searchParams.set("type", "whatsapp");
    clickUrl.searchParams.set("page", listingUrl.href);
    clickUrl.searchParams.set("category", record.category);

    let response;
    try {
      response = await this.fetchImpl(clickUrl, {
        headers: {
          accept: "text/html,application/xhtml+xml",
          "user-agent":
            "AcheiOProfissionalDirectoryReader/1.0 (+public directory extraction)",
        },
        redirect: "manual",
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (error) {
      throw new UpstreamError(
        `Could not resolve the WhatsApp number for ${record.name}.`,
        { cause: error },
      );
    }

    const phone = parseWhatsAppPhone(response.headers.get("location"));
    if (!phone) {
      throw new UpstreamError(
        `The WhatsApp redirect for ${record.name} did not contain a phone number.`,
      );
    }

    this.phoneCache.set(record.sourceId, phone);
    return phone;
  }

  async resolveProfileId(profileUrl) {
    if (!profileUrl) {
      throw new UpstreamError(
        "A featured professional did not include a profile URL.",
      );
    }

    if (this.profileIdCache.has(profileUrl)) {
      return this.profileIdCache.get(profileUrl);
    }

    const url = new URL(profileUrl, this.baseUrl);
    const html = await this.fetchText(url);
    const sourceId = extractFirstProfessionalId(extractNextPayloads(html));

    if (!sourceId) {
      throw new UpstreamError(
        `Could not find the professional ID on ${url.href}.`,
      );
    }

    this.profileIdCache.set(profileUrl, sourceId);
    return sourceId;
  }
}
