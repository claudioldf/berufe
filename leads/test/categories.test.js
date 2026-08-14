import assert from "node:assert/strict";
import test from "node:test";

import { loadCategories, parseCategories } from "../src/categories.js";

test("loads the project category list", async () => {
  const categories = await loadCategories();

  assert.ok(categories.length > 0);
  assert.equal(
    new Set(categories.map((category) => category.slug)).size,
    categories.length,
  );
  assert.deepEqual(
    categories.find((category) => category.slug === "corretor-de-imoveis"),
    {
      name: "Corretor de Imóveis",
      slug: "corretor-de-imoveis",
    },
  );
});

test("rejects invalid and duplicate category slugs", () => {
  assert.throws(
    () => parseCategories('[{"name":"Invalid","slug":"Not Valid"}]'),
    /invalid slug/,
  );
  assert.throws(
    () =>
      parseCategories(
        '[{"name":"One","slug":"same"},{"name":"Two","slug":"same"}]',
      ),
    /Duplicate category slug/,
  );
});
