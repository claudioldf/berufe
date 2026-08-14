import assert from "node:assert/strict";
import test from "node:test";

import { scrapeCity } from "../src/city-scraper.js";

test("scrapes all categories, deduplicates WhatsApp numbers, and reports failures", async () => {
  const progress = [];
  const sleeps = [];
  const categories = [
    { name: "Eletricista", slug: "eletricista" },
    { name: "Encanador", slug: "encanador" },
    { name: "Falha", slug: "falha" },
  ];
  const sharedProfessional = {
    name: "Profissional compartilhado",
    category: "Eletricista",
    city: "São Paulo",
    state: "SP",
    whatsapp: "5511900000000",
  };
  const service = {
    async scrape(category, city) {
      assert.equal(city, "sao-paulo");
      if (category === "falha") throw new Error("HTTP 503");

      return {
        count: category === "eletricista" ? 2 : 1,
        professionals:
          category === "eletricista"
            ? [
                {
                  name: "Somente eletricista",
                  category: "Eletricista",
                  city: "São Paulo",
                  state: "SP",
                  whatsapp: "5511911111111",
                },
                sharedProfessional,
              ]
            : [sharedProfessional],
      };
    },
  };

  const result = await scrapeCity({
    categories,
    categoryConcurrency: 2,
    categoryDelayMs: 250,
    city: "sao-paulo",
    onProgress: (event) => progress.push(event),
    service,
    sleepImpl: async (milliseconds) => sleeps.push(milliseconds),
  });

  assert.equal(result.categoryCount, 3);
  assert.equal(result.categoriesSucceeded, 2);
  assert.equal(result.categoriesFailed, 1);
  assert.equal(result.count, 2);
  const sharedResult = result.professionals.find(
    (professional) => professional.whatsapp === "5511900000000",
  );
  assert.equal(sharedResult.position, 1);
  assert.deepEqual(
    sharedResult.listingCategories,
    [
      { name: "Eletricista", slug: "eletricista", position: 2 },
      { name: "Encanador", slug: "encanador", position: 1 },
    ],
  );
  assert.deepEqual(result.errors, [
    { category: "Falha", slug: "falha", error: "HTTP 503" },
  ]);
  assert.equal(progress.length, 3);
  assert.deepEqual(sleeps, [250, 250]);
});

test("validates the city slug before scraping", async () => {
  await assert.rejects(
    scrapeCity({
      categories: [{ name: "Eletricista", slug: "eletricista" }],
      city: "São Paulo",
      service: { scrape() {} },
    }),
    /city must be a lowercase URL slug/,
  );
});
