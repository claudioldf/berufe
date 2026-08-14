import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import {
  extractEmbeddedProfessionals,
  extractFirstProfessionalId,
  extractHiddenNumberProfessionals,
  extractListingCards,
  extractNextPayloads,
  extractProfileLinks,
  normalizeBrazilianPhone,
  parseWhatsAppPhone,
} from "../src/parser.js";

const fixture = await readFile(
  new URL("./fixtures/list-page.html", import.meta.url),
  "utf8",
);
const payloads = extractNextPayloads(fixture);

test("extracts records whose numbers are embedded in the Next.js payload", () => {
  assert.deepEqual(extractEmbeddedProfessionals(payloads), [
    {
      sourceId: "regular-id",
      name: "Profissional regular",
      category: "Eletricista",
      city: "São Paulo",
      state: "SP",
      whatsapp: "5511987654321",
    },
  ]);
});

test("extracts rendered cards whose numbers require the click redirect", () => {
  assert.deepEqual(extractHiddenNumberProfessionals(payloads), [
    {
      sourceId: "featured-id",
      name: "Profissional em destaque",
      category: "Eletricista",
      city: "São Paulo",
      state: "SP",
      whatsapp: null,
    },
  ]);
});

test("extracts card text from the server-rendered HTML", () => {
  assert.deepEqual(extractListingCards(fixture), [
    {
      sourceId: null,
      profileUrl: null,
      name: "Profissional em destaque",
      category: "Eletricista",
      city: "São Paulo",
      state: "SP",
      whatsapp: null,
    },
  ]);
  assert.equal(extractFirstProfessionalId(payloads), "featured-id");
  assert.deepEqual(extractProfileLinks(fixture), [
    {
      name: "Profissional em destaque",
      profileUrl:
        "https://acheioprofissional.com.br/profissional/profissional-em-destaque",
    },
  ]);
});

test("normalizes Brazilian numbers and reads both supported WhatsApp URLs", () => {
  assert.equal(normalizeBrazilianPhone("(11) 98765-4321"), "5511987654321");
  assert.equal(
    parseWhatsAppPhone("https://api.whatsapp.com/send/?phone=5511987654321"),
    "5511987654321",
  );
  assert.equal(
    parseWhatsAppPhone("https://wa.me/5511987654321?text=Oi"),
    "5511987654321",
  );
});
