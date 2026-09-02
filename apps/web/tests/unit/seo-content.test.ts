import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  buildLocalServiceSchema,
  buildLocalSitemapUrls,
  buildProviderSitemapUrls,
  hasPublishedSeoContent,
  isLocalPageIndexable,
  localSeoRoute,
} from "@app/utils/seoContent";

function markdownFiles(directory: string): string[] {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = resolve(directory, entry.name);
    return entry.isDirectory()
      ? markdownFiles(path)
      : entry.name.endsWith(".md")
        ? [path]
        : [];
  });
}

function readMarkdown(path: string) {
  const source = readFileSync(path, "utf8");
  const match = source.match(/^---\n([\s\S]+?)\n---\n([\s\S]+)$/);
  if (!match) throw new Error(`Invalid frontmatter in ${path}`);

  const frontmatter = new Map(
    match[1]!.split("\n").map((line) => {
      const separator = line.indexOf(":");
      return [line.slice(0, separator), line.slice(separator + 1).trim()];
    }),
  );
  const value = (key: string) => {
    const raw = frontmatter.get(key);
    if (raw === undefined) throw new Error(`Missing ${key} in ${path}`);
    return raw.startsWith('"') ? JSON.parse(raw) : raw;
  };

  return { body: match[2]!.trim(), value };
}

function trigrams(text: string): Set<string> {
  const words = text
    .toLocaleLowerCase("pt-BR")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim()
    .split(/\s+/);
  return new Set(
    words
      .slice(0, -2)
      .map((_, index) => words.slice(index, index + 3).join(" ")),
  );
}

function jaccardSimilarity(left: Set<string>, right: Set<string>): number {
  const intersection = [...left].filter((value) => right.has(value)).length;
  return intersection / (left.size + right.size - intersection);
}

describe("SEO publication gates", () => {
  it("requires both real supply and published editorial content", () => {
    expect(hasPublishedSeoContent({ published: true })).toBe(true);
    expect(hasPublishedSeoContent({ published: false })).toBe(false);
    expect(isLocalPageIndexable(true, { published: true })).toBe(true);
    expect(isLocalPageIndexable(false, { published: true })).toBe(false);
    expect(isLocalPageIndexable(true, null)).toBe(false);
  });

  it("builds a stable profession and city route", () => {
    expect(
      localSeoRoute({
        stateSlug: "sc",
        citySlug: "joinville",
        serviceSlug: "pedreiro",
      }),
    ).toBe("/encontrar/sc/joinville/pedreiro");
  });
});

describe("SEO sitemaps", () => {
  it("includes only listings that have supply and published content", () => {
    const urls = buildLocalSitemapUrls(
      [
        {
          stateSlug: "sc",
          citySlug: "joinville",
          serviceSlug: "pedreiro",
          indexable: true,
        },
        {
          stateSlug: "sc",
          citySlug: "joinville",
          serviceSlug: "pintor",
          indexable: false,
        },
        {
          stateSlug: "pr",
          citySlug: "curitiba",
          serviceSlug: "eletricista",
          indexable: true,
        },
      ],
      [
        {
          stateSlug: "sc",
          citySlug: "joinville",
          serviceSlug: "pedreiro",
          publishedAt: "2026-09-01",
          updatedAt: "2026-09-02",
        },
        {
          stateSlug: "sc",
          citySlug: "joinville",
          serviceSlug: "pintor",
          publishedAt: "2026-09-01",
        },
      ],
    );

    expect(urls).toEqual([
      {
        loc: "/encontrar/sc/joinville/pedreiro",
        lastmod: "2026-09-02",
      },
      { loc: "/encontrar/sc/joinville" },
      { loc: "/servicos/pedreiro" },
    ]);
  });

  it("publishes acquisition pages with their editorial dates", () => {
    expect(
      buildProviderSitemapUrls(
        [
          {
            serviceSlug: "pedreiro",
            publishedAt: "2026-09-01",
            updatedAt: "2026-09-02",
          },
          {
            serviceSlug: "servico-removido",
            publishedAt: "2026-09-01",
          },
        ],
        ["pedreiro"],
      ),
    ).toEqual([
      { loc: "/para-profissionais" },
      {
        loc: "/para-profissionais/pedreiro",
        lastmod: "2026-09-02",
      },
    ]);
  });
});

describe("local Service schema", () => {
  it("describes the service area and links only real profile providers", () => {
    const schema = buildLocalServiceSchema({
      canonicalUrl: "https://berufe.com.br/encontrar/sc/joinville/pedreiro",
      siteRoot: "https://berufe.com.br",
      serviceName: "Pedreiro",
      cityName: "Joinville",
      stateCode: "SC",
      description: "Profissionais de construção em Joinville.",
      professionals: [{ name: "João Silva", slug: "joao-silva" }],
    });

    expect(schema).toMatchObject({
      "@type": "Service",
      serviceType: "Pedreiro",
      areaServed: {
        "@type": "City",
        name: "Joinville",
        containedInPlace: {
          "@type": "State",
          name: "SC",
          containedInPlace: { "@type": "Country", name: "Brasil" },
        },
      },
      provider: [
        {
          "@type": "Person",
          name: "João Silva",
          url: "https://berufe.com.br/be/joao-silva",
        },
      ],
    });
    expect(schema).not.toHaveProperty("address");
  });
});

describe("editorial SEO inventory", () => {
  it("contains 100 unique local pages across four cities and 25 services", () => {
    const files = markdownFiles(resolve(process.cwd(), "content/locais"));
    const pages = files.map(readMarkdown);

    expect(files).toHaveLength(100);
    expect(new Set(pages.map((page) => page.body))).toHaveLength(100);
    expect(new Set(pages.map((page) => page.value("title")))).toHaveLength(100);
    expect(
      new Set(pages.map((page) => page.value("description"))),
    ).toHaveLength(100);
    expect(
      new Set(pages.map((page) => page.value("serviceSlug"))),
    ).toHaveLength(25);

    const cityCounts = Object.groupBy(pages, (page) => page.value("citySlug"));
    expect(Object.keys(cityCounts)).toHaveLength(4);
    expect(
      Object.values(cityCounts)
        .map((cityPages) => cityPages?.length)
        .sort(),
    ).toEqual([25, 25, 25, 25]);

    const pagesByService = Object.groupBy(pages, (page) =>
      page.value("serviceSlug"),
    );
    let highestSameServiceSimilarity = 0;
    for (const servicePages of Object.values(pagesByService)) {
      for (let left = 0; left < (servicePages?.length ?? 0); left += 1) {
        for (
          let right = left + 1;
          right < (servicePages?.length ?? 0);
          right += 1
        ) {
          highestSameServiceSimilarity = Math.max(
            highestSameServiceSimilarity,
            jaccardSimilarity(
              trigrams(servicePages![left]!.body),
              trigrams(servicePages![right]!.body),
            ),
          );
        }
      }
    }
    expect(highestSameServiceSimilarity).toBeLessThan(0.65);

    for (const page of pages) {
      expect(page.value("published")).toBe("true");
      expect(page.value("title").length).toBeGreaterThanOrEqual(20);
      expect(page.value("title").length).toBeLessThanOrEqual(90);
      expect(page.value("description").length).toBeGreaterThanOrEqual(70);
      expect(page.value("description").length).toBeLessThanOrEqual(180);
      expect(page.body.match(/^## /gm)).toHaveLength(3);
      expect(page.body.split(/\s+/).length).toBeGreaterThanOrEqual(325);
    }
  });

  it("contains one unique acquisition page for every service", () => {
    const files = markdownFiles(
      resolve(process.cwd(), "content/para-profissionais"),
    );
    const pages = files.map(readMarkdown);

    expect(files).toHaveLength(25);
    expect(new Set(pages.map((page) => page.body))).toHaveLength(25);
    expect(
      new Set(pages.map((page) => page.value("serviceSlug"))),
    ).toHaveLength(25);

    for (const page of pages) {
      expect(page.value("published")).toBe("true");
      expect(page.value("title").length).toBeGreaterThanOrEqual(20);
      expect(page.value("title").length).toBeLessThanOrEqual(90);
      expect(page.value("description").length).toBeGreaterThanOrEqual(70);
      expect(page.value("description").length).toBeLessThanOrEqual(180);
      expect(page.body.match(/^## /gm)).toHaveLength(3);
      expect(page.body.split(/\s+/).length).toBeGreaterThanOrEqual(250);
    }
  });
});
