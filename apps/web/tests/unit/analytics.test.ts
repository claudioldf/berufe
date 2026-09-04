import { analyticsPagePath } from "@app/utils/analytics";

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
