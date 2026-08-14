import http from "node:http";
import { pathToFileURL } from "node:url";

import { AcheiOProfissionalService } from "./achei-o-profissional-service.js";
import { ValidationError } from "./errors.js";

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  });
  response.end(`${JSON.stringify(body)}\n`);
}

function routeParameters(url) {
  const pathMatch = url.pathname.match(
    /^\/api\/professionals\/([^/]+)\/([^/]+)\/?$/,
  );

  if (pathMatch) {
    return {
      category: decodeURIComponent(pathMatch[1]),
      city: decodeURIComponent(pathMatch[2]),
    };
  }

  if (url.pathname === "/api/professionals") {
    return {
      category: url.searchParams.get("category"),
      city: url.searchParams.get("city"),
    };
  }

  return null;
}

export function createServer({ service = new AcheiOProfissionalService() } = {}) {
  return http.createServer(async (request, response) => {
    const url = new URL(request.url, "http://localhost");

    if (request.method === "GET" && url.pathname === "/health") {
      sendJson(response, 200, { status: "ok" });
      return;
    }

    const parameters = request.method === "GET" ? routeParameters(url) : null;
    if (!parameters) {
      sendJson(response, 404, { error: "Not found" });
      return;
    }

    try {
      if (!parameters.category || !parameters.city) {
        throw new ValidationError("category and city are required.");
      }

      const result = await service.scrape(parameters.category, parameters.city);
      sendJson(response, 200, result);
    } catch (error) {
      const statusCode = error.statusCode ?? 500;
      const message =
        statusCode === 500 ? "An unexpected error occurred." : error.message;
      sendJson(response, statusCode, { error: message });
    }
  });
}

function parsePort(value) {
  const port = Number.parseInt(value ?? "3000", 10);
  if (!Number.isInteger(port) || port < 1 || port > 65_535) {
    throw new Error("PORT must be an integer between 1 and 65535.");
  }
  return port;
}

const isMain =
  process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;

if (isMain) {
  const service = new AcheiOProfissionalService({
    cacheTtlMs: Number.parseInt(process.env.CACHE_TTL_MS ?? "900000", 10),
    timeoutMs: Number.parseInt(process.env.UPSTREAM_TIMEOUT_MS ?? "20000", 10),
  });
  const server = createServer({ service });
  const port = parsePort(process.env.PORT);

  server.listen(port, () => {
    console.log(`Achei o Profissional scraper listening on port ${port}`);
  });
}
