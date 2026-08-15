import { describe, expect, it } from "vitest";
import { normalizeSocialProfile } from "~/utils/socialProfiles";
import { normalizeSearchText, toIdentifier } from "~/utils/text";

describe("text utilities", () => {
  it("normalizes accents and casing for search", () => {
    expect(normalizeSearchText("  Elétrica São José ")).toBe(
      "eletrica sao jose",
    );
  });

  it("creates stable catalog identifiers", () => {
    expect(toIdentifier("Jardim Iririú / Norte")).toBe("jardim-iririu-norte");
  });
});

describe("social profile normalization", () => {
  it("accepts handles and emits canonical URLs", () => {
    expect(normalizeSocialProfile("@berufe", "instagram")).toEqual({
      url: "https://www.instagram.com/berufe/",
      error: "",
    });
    expect(normalizeSocialProfile("@canal-berufe", "youtube")).toEqual({
      url: "https://www.youtube.com/@canal-berufe",
      error: "",
    });
  });

  it("rejects off-platform and nested URLs", () => {
    expect(
      normalizeSocialProfile("https://example.com/berufe", "instagram").error,
    ).toContain("Instagram");
    expect(
      normalizeSocialProfile(
        "https://youtube.com/channel/not-a-handle",
        "youtube",
      ).error,
    ).toContain("YouTube");
  });
});
