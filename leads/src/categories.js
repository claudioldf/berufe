import { readFile } from "node:fs/promises";

import { ValidationError } from "./errors.js";

const CATEGORY_SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const DEFAULT_CATEGORIES_URL = new URL("../categories.json", import.meta.url);

export function parseCategories(contents) {
  let value;

  try {
    value = JSON.parse(contents);
  } catch (error) {
    throw new ValidationError(`categories.json is not valid JSON: ${error.message}`);
  }

  if (!Array.isArray(value)) {
    throw new ValidationError("categories.json must contain a JSON array.");
  }

  const seenSlugs = new Set();
  return value.map((category, index) => {
    if (!category || typeof category !== "object") {
      throw new ValidationError(`Category at index ${index} must be an object.`);
    }

    const name = String(category.name ?? "").trim();
    const slug = String(category.slug ?? "").trim();

    if (!name) {
      throw new ValidationError(`Category at index ${index} is missing a name.`);
    }
    if (!CATEGORY_SLUG_PATTERN.test(slug)) {
      throw new ValidationError(
        `Category "${name}" has an invalid slug: "${slug}".`,
      );
    }
    if (seenSlugs.has(slug)) {
      throw new ValidationError(`Duplicate category slug: "${slug}".`);
    }

    seenSlugs.add(slug);
    return { name, slug };
  });
}

export async function loadCategories(url = DEFAULT_CATEGORIES_URL) {
  return parseCategories(await readFile(url, "utf8"));
}
