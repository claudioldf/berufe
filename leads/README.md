# Achei o Profissional extraction service

Small, dependency-free Node.js service that reads a public listing at:

```text
https://acheioprofissional.com.br/{category}/{city}
```

It returns each professional's name, category, city, state (UF), and WhatsApp
number. Numbers are normalized to digits in Brazilian international format
(`55` + DDD + local number).

## Requirements

- Node.js 22 or newer

## Run the HTTP service

```bash
npm start
```

Then request a listing with path parameters:

```bash
curl http://localhost:3000/api/professionals/eletricista/sao-paulo
```

or query parameters:

```bash
curl 'http://localhost:3000/api/professionals?category=eletricista&city=sao-paulo'
```

Example response:

```json
{
  "sourceUrl": "https://acheioprofissional.com.br/eletricista/sao-paulo",
  "count": 2,
  "professionals": [
    {
      "name": "Nome do profissional",
      "category": "Eletricista",
      "position": 1,
      "city": "São Paulo",
      "state": "SP",
      "whatsapp": "5511987654321"
    }
  ]
}
```

The category and city values are URL slugs, such as `corretor-de-imoveis` and
`sao-paulo`.

## Scrape every category for one city

The CLI loads all categories from `categories.json`. Provide the city slug and
an optional output format:

```bash
npm run scrape -- sao-paulo cli
npm run scrape -- sao-paulo json
npm run scrape -- sao-paulo csv
```

The formats behave as follows:

- `cli` prints formatted JSON to stdout (and is the default).
- `json` writes `results/sao-paulo.json`.
- `csv` writes `results/sao-paulo.csv`.

The `results` directory is created automatically when needed.

Progress is always written to stderr. To redirect clean CLI JSON without npm's
command banner:

```bash
npm run --silent scrape -- sao-paulo cli > sao-paulo.json
```

Professionals found in more than one category listing are deduplicated by
WhatsApp number. Their `listingCategories` array records every category page
where they appeared and their position on that page. Position is one-based, so
`1` is the strongest placement. A deduplicated professional's top-level
`position` is the best (lowest) position found across all categories. Failed
categories are listed in the top-level `errors` array for JSON/CLI output while
successful results are preserved. CSV contains professional rows only;
category failures remain visible in stderr and produce exit code `2`.

Category request starts are spaced one second apart by default, even when
multiple pages run concurrently. Concurrency and delay can be adjusted
carefully:

```bash
CATEGORY_CONCURRENCY=3 CATEGORY_DELAY_MS=1500 npm run scrape -- sao-paulo csv
```

## How extraction works

The listing currently includes most phone numbers in its server-rendered
Next.js data. Featured cards keep the number behind the same internal redirect
used by the **Chamar no WhatsApp** button. The service reads the embedded data
first and only requests that redirect for records whose number is hidden.

Results and resolved hidden numbers are cached in memory for 15 minutes, which
reduces repeat traffic and avoids repeatedly registering button redirects.

Configuration:

| Variable | Default | Meaning |
| --- | ---: | --- |
| `PORT` | `3000` | HTTP port |
| `CACHE_TTL_MS` | `900000` | Result cache duration |
| `UPSTREAM_TIMEOUT_MS` | `20000` | Timeout per upstream request |
| `CATEGORY_CONCURRENCY` | `2` | Simultaneous category pages used by the CLI (maximum `10`) |
| `CATEGORY_DELAY_MS` | `1000` | Delay between category request starts (maximum `60000`) |

## Test

```bash
npm test
```

The test suite uses local fixtures and does not contact the live website.

Use the service in accordance with the source site's terms, applicable privacy
rules, and reasonable request rates.
