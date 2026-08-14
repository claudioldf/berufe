import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { AcheiOProfissionalService } from "../src/achei-o-profissional-service.js";

const fixture = await readFile(
  new URL("./fixtures/list-page.html", import.meta.url),
  "utf8",
);

test("scrapes the listing, resolves hidden numbers, and caches the result", async () => {
  const calls = [];
  const fetchImpl = async (input, options = {}) => {
    const url = new URL(input);
    calls.push({ url: url.href, redirect: options.redirect });

    if (url.pathname === "/eletricista/sao-paulo") {
      return new Response(fixture, {
        headers: { "content-type": "text/html; charset=utf-8" },
      });
    }

    if (url.pathname === "/api/click/featured-id") {
      return new Response(null, {
        status: 307,
        headers: {
          location:
            "https://api.whatsapp.com/send/?phone=5511912345678&text=Oi",
        },
      });
    }

    return new Response("Not found", { status: 404 });
  };

  const service = new AcheiOProfissionalService({ fetchImpl });
  const result = await service.scrape("eletricista", "sao-paulo");

  assert.deepEqual(result, {
    sourceUrl: "https://acheioprofissional.com.br/eletricista/sao-paulo",
    count: 2,
    professionals: [
      {
        name: "Profissional em destaque",
        category: "Eletricista",
        city: "São Paulo",
        state: "SP",
        whatsapp: "5511912345678",
        position: 1,
      },
      {
        name: "Profissional regular",
        category: "Eletricista",
        city: "São Paulo",
        state: "SP",
        whatsapp: "5511987654321",
        position: 2,
      },
    ],
  });
  assert.equal(calls.length, 2);
  assert.equal(calls[1].redirect, "manual");

  assert.deepEqual(
    await service.scrape("eletricista", "sao-paulo"),
    result,
  );
  assert.equal(calls.length, 2);
});

test("rejects unsafe category and city path values before fetching", async () => {
  const service = new AcheiOProfissionalService({
    fetchImpl: () => {
      throw new Error("fetch should not run");
    },
  });

  await assert.rejects(
    service.scrape("../admin", "sao-paulo"),
    /category must be a lowercase URL slug/,
  );
  await assert.rejects(
    service.scrape("eletricista", "São Paulo"),
    /city must be a lowercase URL slug/,
  );
});

test("preserves separate upstream records that share a displayed name", async () => {
  const duplicateFixture = `
    <script>self.__next_f.push([1,"49:{\\"professionals\\":[{\\"id\\":\\"one\\",\\"businessName\\":\\"Mesmo nome\\",\\"whatsapp\\":\\"11911111111\\",\\"city\\":{\\"name\\":\\"São Paulo\\",\\"uf\\":\\"SP\\"},\\"categories\\":[{\\"isPrimary\\":true,\\"category\\":{\\"name\\":\\"Eletricista\\"}}]},{\\"id\\":\\"two\\",\\"businessName\\":\\"Mesmo nome\\",\\"whatsapp\\":\\"11922222222\\",\\"city\\":{\\"name\\":\\"São Paulo\\",\\"uf\\":\\"SP\\"},\\"categories\\":[{\\"isPrimary\\":true,\\"category\\":{\\"name\\":\\"Eletricista\\"}}]}]}"])</script>
  `;
  const service = new AcheiOProfissionalService({
    fetchImpl: async () => new Response(duplicateFixture),
  });

  const result = await service.scrape("eletricista", "sao-paulo");

  assert.equal(result.count, 2);
  assert.deepEqual(
    result.professionals.map((professional) => professional.whatsapp),
    ["5511911111111", "5511922222222"],
  );
});

test("loads a featured profile when its ID is not serialized on the listing", async () => {
  const listing = `
    <p title="Perfil sem ID">Perfil sem ID</p>
    <p>Eletricista · São Paulo, SP</p>
    <script type="application/ld+json">{"@type":"ItemList","itemListElement":[{"name":"Perfil sem ID","url":"https://acheioprofissional.com.br/profissional/perfil-sem-id"}]}</script>
  `;
  const profile = `
    <script>self.__next_f.push([1,"1:{\\"professionalId\\":\\"profile-id\\"}"])</script>
  `;
  const calls = [];
  const service = new AcheiOProfissionalService({
    fetchImpl: async (input) => {
      const url = new URL(input);
      calls.push(url.pathname);
      if (url.pathname === "/eletricista/sao-paulo") {
        return new Response(listing);
      }
      if (url.pathname === "/profissional/perfil-sem-id") {
        return new Response(profile);
      }
      if (url.pathname === "/api/click/profile-id") {
        return new Response(null, {
          status: 307,
          headers: { location: "https://wa.me/5511900000000" },
        });
      }
      return new Response("Not found", { status: 404 });
    },
  });

  const result = await service.scrape("eletricista", "sao-paulo");

  assert.equal(result.count, 1);
  assert.equal(result.professionals[0].whatsapp, "5511900000000");
  assert.deepEqual(calls, [
    "/eletricista/sao-paulo",
    "/profissional/perfil-sem-id",
    "/api/click/profile-id",
  ]);
});
