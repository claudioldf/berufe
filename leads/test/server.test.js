import assert from "node:assert/strict";
import test from "node:test";

import { createServer } from "../src/server.js";

async function listen(server) {
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  return server.address().port;
}

async function close(server) {
  await new Promise((resolve, reject) =>
    server.close((error) => (error ? reject(error) : resolve())),
  );
}

test("serves health and professional extraction endpoints", async (context) => {
  const calls = [];
  const expected = {
    sourceUrl: "https://acheioprofissional.com.br/eletricista/sao-paulo",
    count: 0,
    professionals: [],
  };
  const server = createServer({
    service: {
      async scrape(category, city) {
        calls.push({ category, city });
        return expected;
      },
    },
  });
  const port = await listen(server);
  context.after(() => close(server));

  const health = await fetch(`http://127.0.0.1:${port}/health`).then((response) =>
    response.json(),
  );
  assert.deepEqual(health, { status: "ok" });

  const response = await fetch(
    `http://127.0.0.1:${port}/api/professionals/eletricista/sao-paulo`,
  );
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), expected);
  assert.deepEqual(calls, [{ category: "eletricista", city: "sao-paulo" }]);
});
