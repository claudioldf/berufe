const SCRIPT_PATTERN = /<script\b[^>]*>([\s\S]*?)<\/script>/gi;
const PROFESSIONALS_MARKER = '"professionals":[';
const LOCATION_PATTERN = /"children":\[("(?:\\.|[^"\\])*")," · ",("(?:\\.|[^"\\])*"),", ",("(?:\\.|[^"\\])*")\]/g;
const PROFESSIONAL_ID_PATTERN = /"professionalId":("(?:\\.|[^"\\])*")/g;
const CARD_PATTERN = /<p\b[^>]*\btitle=(['"])(.*?)\1[^>]*>[\s\S]*?<\/p>\s*<p\b[^>]*>([\s\S]*?)<\/p>/gi;
const JSON_LD_PATTERN = /<script\b[^>]*\btype=(['"])application\/ld\+json\1[^>]*>([\s\S]*?)<\/script>/gi;

function parseJsonString(value) {
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}

function decodeHtml(value) {
  const namedEntities = {
    amp: "&",
    apos: "'",
    gt: ">",
    lt: "<",
    nbsp: " ",
    quot: '"',
  };

  return value.replace(
    /&(?:#(\d+)|#x([\da-f]+)|([a-z]+));/gi,
    (entity, decimal, hexadecimal, named) => {
      if (decimal) return String.fromCodePoint(Number.parseInt(decimal, 10));
      if (hexadecimal) {
        return String.fromCodePoint(Number.parseInt(hexadecimal, 16));
      }
      return namedEntities[named.toLowerCase()] ?? entity;
    },
  );
}

function plainText(html) {
  return decodeHtml(
    html.replace(/<!--[\s\S]*?-->/g, "").replace(/<[^>]+>/g, ""),
  )
    .replace(/\s+/g, " ")
    .trim();
}

function readJsonStringProperty(source, property, startAt = 0) {
  const marker = `"${property}":`;
  const markerIndex = source.indexOf(marker, startAt);

  if (markerIndex < 0) return null;

  const valueStart = markerIndex + marker.length;
  if (source[valueStart] !== '"') return null;

  let escaped = false;
  for (let index = valueStart + 1; index < source.length; index += 1) {
    const character = source[index];

    if (escaped) {
      escaped = false;
      continue;
    }

    if (character === "\\") {
      escaped = true;
      continue;
    }

    if (character === '"') {
      return parseJsonString(source.slice(valueStart, index + 1));
    }
  }

  return null;
}

function extractBalancedArray(source, arrayStart) {
  let depth = 0;
  let inString = false;
  let escaped = false;

  for (let index = arrayStart; index < source.length; index += 1) {
    const character = source[index];

    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (character === "\\") {
        escaped = true;
      } else if (character === '"') {
        inString = false;
      }
      continue;
    }

    if (character === '"') {
      inString = true;
    } else if (character === "[") {
      depth += 1;
    } else if (character === "]") {
      depth -= 1;
      if (depth === 0) return source.slice(arrayStart, index + 1);
    }
  }

  return null;
}

export function extractNextPayloads(html) {
  const payloads = [];

  for (const scriptMatch of html.matchAll(SCRIPT_PATTERN)) {
    const script = scriptMatch[1].trim();
    const prefix = "self.__next_f.push(";
    const callStart = script.indexOf(prefix);
    const callEnd = script.lastIndexOf(")");

    if (callStart < 0 || callEnd < 0) continue;

    try {
      const value = JSON.parse(script.slice(callStart + prefix.length, callEnd));
      if (typeof value?.[1] === "string") payloads.push(value[1]);
    } catch {
      // Ignore unrelated or incomplete script tags.
    }
  }

  return payloads;
}

export function normalizeBrazilianPhone(value) {
  const digits = String(value ?? "").replace(/\D/g, "");

  if (/^55\d{10,11}$/.test(digits)) return digits;
  if (/^\d{10,11}$/.test(digits)) return `55${digits}`;
  return digits || null;
}

function primaryCategory(professional) {
  const categories = Array.isArray(professional.categories)
    ? professional.categories
    : [];
  const selected = categories.find((item) => item?.isPrimary) ?? categories[0];
  return selected?.category?.name ?? null;
}

export function extractEmbeddedProfessionals(payloads) {
  const records = [];

  for (const payload of payloads) {
    let searchAt = 0;

    while (searchAt < payload.length) {
      const markerIndex = payload.indexOf(PROFESSIONALS_MARKER, searchAt);
      if (markerIndex < 0) break;

      const arrayStart = markerIndex + PROFESSIONALS_MARKER.length - 1;
      const encodedArray = extractBalancedArray(payload, arrayStart);
      searchAt = arrayStart + 1;

      if (!encodedArray) continue;

      try {
        const professionals = JSON.parse(encodedArray);

        for (const professional of professionals) {
          if (!professional?.businessName || !professional?.city) continue;

          records.push({
            sourceId: professional.id ?? null,
            name: professional.businessName,
            category: primaryCategory(professional),
            city: professional.city.name ?? null,
            state: professional.city.uf ?? null,
            whatsapp: normalizeBrazilianPhone(professional.whatsapp),
          });
        }
      } catch {
        // A future Next.js payload may not be plain JSON; the featured-card
        // parser can still return the records rendered in the page.
      }
    }
  }

  return records;
}

export function extractHiddenNumberProfessionals(payloads) {
  const records = [];
  const seenIds = new Set();
  const payload = payloads.join("");

  for (const idMatch of payload.matchAll(PROFESSIONAL_ID_PATTERN)) {
    const sourceId = parseJsonString(idMatch[1]);
    if (!sourceId || seenIds.has(sourceId)) continue;

    const context = payload.slice(0, idMatch.index);
    const titleIndex = context.lastIndexOf('"title":');
    if (titleIndex < 0) continue;

    const card = context.slice(titleIndex);
    const name = readJsonStringProperty(card, "title");
    const locations = [...card.matchAll(LOCATION_PATTERN)];
    const location = locations.at(-1);

    if (!name || !location) continue;

    const category = parseJsonString(location[1]);
    const city = parseJsonString(location[2]);
    const state = parseJsonString(location[3]);
    if (!category || !city || !state) continue;

    seenIds.add(sourceId);
    records.push({
      sourceId,
      name,
      category,
      city,
      state,
      whatsapp: null,
    });
  }

  return records;
}

export function extractListingCards(html) {
  const records = [];

  for (const match of html.matchAll(CARD_PATTERN)) {
    const location = plainText(match[3]).match(
      /^(.*?)\s+·\s+(.+?),\s*([A-Z]{2})$/u,
    );
    if (!location) continue;

    records.push({
      sourceId: null,
      profileUrl: null,
      name: decodeHtml(match[2]).trim(),
      category: location[1].trim(),
      city: location[2].trim(),
      state: location[3],
      whatsapp: null,
    });
  }

  return records;
}

export function extractProfileLinks(html) {
  for (const match of html.matchAll(JSON_LD_PATTERN)) {
    try {
      const data = JSON.parse(match[2]);
      if (data?.["@type"] !== "ItemList") continue;

      return (data.itemListElement ?? [])
        .filter((item) => item?.name && item?.url)
        .map((item) => ({ name: item.name, profileUrl: item.url }));
    } catch {
      // Ignore malformed or unrelated structured-data blocks.
    }
  }

  return [];
}

export function extractFirstProfessionalId(payloads) {
  const match = payloads.join("").matchAll(PROFESSIONAL_ID_PATTERN).next().value;
  return match ? parseJsonString(match[1]) : null;
}

export function parseWhatsAppPhone(location) {
  if (!location) return null;

  try {
    const url = new URL(location, "https://acheioprofissional.com.br");
    const queryPhone = url.searchParams.get("phone");
    if (queryPhone) return normalizeBrazilianPhone(queryPhone);

    if (/^(?:api\.)?whatsapp\.com$/i.test(url.hostname)) {
      return normalizeBrazilianPhone(url.pathname.match(/\/send\/(\d+)/)?.[1]);
    }

    if (/^(?:www\.)?wa\.me$/i.test(url.hostname)) {
      return normalizeBrazilianPhone(url.pathname.split("/").filter(Boolean)[0]);
    }
  } catch {
    return null;
  }

  return null;
}
