import { ValidationError } from "./errors.js";

const CITY_SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const DEFAULT_CATEGORY_DELAY_MS = 1_000;

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function professionalKey(professional) {
  if (professional.whatsapp) return `whatsapp:${professional.whatsapp}`;

  return [professional.name, professional.city, professional.state]
    .map((value) => String(value ?? "").trim().toLocaleLowerCase("pt-BR"))
    .join("|");
}

function addProfessionals(target, category, professionals) {
  for (const [index, professional] of professionals.entries()) {
    const position = Number.isInteger(professional.position)
      ? professional.position
      : index + 1;
    const key = professionalKey(professional);
    const existing = target.get(key);
    const listingCategory = {
      name: category.name,
      slug: category.slug,
      position,
    };

    if (existing) {
      existing.position = Math.min(existing.position, position);
      const existingCategory = existing.listingCategories.find(
        (item) => item.slug === listingCategory.slug,
      );

      if (existingCategory) {
        existingCategory.position = Math.min(
          existingCategory.position,
          position,
        );
      } else {
        existing.listingCategories.push(listingCategory);
      }
      continue;
    }

    target.set(key, {
      ...professional,
      position,
      listingCategories: [listingCategory],
    });
  }
}

export async function scrapeCity({
  categories,
  categoryConcurrency = 2,
  categoryDelayMs = DEFAULT_CATEGORY_DELAY_MS,
  city,
  onProgress = () => {},
  service,
  sleepImpl = sleep,
}) {
  if (!CITY_SLUG_PATTERN.test(city ?? "")) {
    throw new ValidationError(
      "city must be a lowercase URL slug containing only letters, numbers, and hyphens.",
    );
  }
  if (!Array.isArray(categories) || categories.length === 0) {
    throw new ValidationError("At least one category is required.");
  }
  if (
    !Number.isInteger(categoryConcurrency) ||
    categoryConcurrency < 1 ||
    categoryConcurrency > 10
  ) {
    throw new ValidationError(
      "categoryConcurrency must be an integer between 1 and 10.",
    );
  }
  if (
    !Number.isInteger(categoryDelayMs) ||
    categoryDelayMs < 0 ||
    categoryDelayMs > 60_000
  ) {
    throw new ValidationError(
      "categoryDelayMs must be an integer between 0 and 60000.",
    );
  }
  if (!service || typeof service.scrape !== "function") {
    throw new TypeError("A scraper service is required.");
  }

  const results = new Array(categories.length);
  let nextIndex = 0;
  let completed = 0;
  let firstCategoryStarted = false;
  let startQueue = Promise.resolve();

  function waitForStartSlot() {
    const turn = startQueue.then(async () => {
      if (firstCategoryStarted && categoryDelayMs > 0) {
        await sleepImpl(categoryDelayMs);
      }
      firstCategoryStarted = true;
    });
    startQueue = turn.catch(() => {});
    return turn;
  }

  async function worker() {
    while (nextIndex < categories.length) {
      const index = nextIndex;
      nextIndex += 1;
      const category = categories[index];

      try {
        await waitForStartSlot();
        const result = await service.scrape(category.slug, city);
        results[index] = { category, result };
      } catch (error) {
        results[index] = {
          category,
          error: error instanceof Error ? error.message : String(error),
        };
      }

      completed += 1;
      onProgress({
        category,
        completed,
        error: results[index].error ?? null,
        professionalCount: results[index].result?.count ?? 0,
        total: categories.length,
      });
    }
  }

  await Promise.all(
    Array.from(
      { length: Math.min(categoryConcurrency, categories.length) },
      () => worker(),
    ),
  );

  const professionalsByKey = new Map();
  const errors = [];

  for (const item of results) {
    if (item.error) {
      errors.push({
        category: item.category.name,
        slug: item.category.slug,
        error: item.error,
      });
      continue;
    }

    addProfessionals(
      professionalsByKey,
      item.category,
      item.result.professionals,
    );
  }

  const professionals = [...professionalsByKey.values()];
  return {
    city,
    categoryCount: categories.length,
    categoriesSucceeded: categories.length - errors.length,
    categoriesFailed: errors.length,
    count: professionals.length,
    professionals,
    errors,
  };
}
