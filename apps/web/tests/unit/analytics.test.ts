import { analyticsPagePath, analyticsSearchTerm } from "@app/utils/analytics";

describe("analyticsPagePath", () => {
  it("leaves an ordinary public path unchanged", () => {
    expect(analyticsPagePath("/servicos/eletricista")).toBe(
      "/servicos/eletricista",
    );
  });

  it("leaves the site root unchanged", () => {
    expect(analyticsPagePath("/")).toBe("/");
  });

  it("redacts a quote link token", () => {
    expect(analyticsPagePath("/orcamento/abc123def456")).toBe(
      "/orcamento/[token]",
    );
  });

  it("redacts a recommendation link token with a query string", () => {
    expect(analyticsPagePath("/recomendacao/xyz789?utm_source=whatsapp")).toBe(
      "/recomendacao/[token]",
    );
  });

  it("redacts an account-deletion status token with a hash", () => {
    expect(analyticsPagePath("/exclusao-de-conta/tok123#status")).toBe(
      "/exclusao-de-conta/[token]",
    );
  });

  it("redacts a token path with a trailing slash", () => {
    expect(analyticsPagePath("/orcamento/abc123/")).toBe("/orcamento/[token]");
  });

  it("does not redact a bare token route prefix", () => {
    expect(analyticsPagePath("/orcamento")).toBe("/orcamento");
  });
});

describe("analyticsSearchTerm", () => {
  it("joins the matched service and city", () => {
    expect(analyticsSearchTerm(["Eletricista"], "Joinville")).toBe(
      "Eletricista - Joinville",
    );
  });

  it("uses only the first matched service", () => {
    expect(analyticsSearchTerm(["Eletricista", "Encanador"], "Joinville")).toBe(
      "Eletricista - Joinville",
    );
  });

  it("falls back to the service alone when there is no city", () => {
    expect(analyticsSearchTerm(["Eletricista"], null)).toBe("Eletricista");
  });

  it("falls back to the city alone when no service matched", () => {
    expect(analyticsSearchTerm([], "Joinville")).toBe("Joinville");
  });

  it("returns an empty string when neither is available", () => {
    expect(analyticsSearchTerm([], undefined)).toBe("");
  });
});
