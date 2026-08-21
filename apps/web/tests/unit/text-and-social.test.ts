import { describe, expect, it } from "vitest";
import { normalizeSocialProfile } from "~/utils/socialProfiles";
import {
  formatCountLabel,
  normalizeSearchText,
  toIdentifier,
} from "~/utils/text";

describe("text utilities", () => {
  it("normalizes accents and casing for search", () => {
    expect(normalizeSearchText("  Elétrica São José ")).toBe(
      "eletrica sao jose",
    );
  });

  it("creates stable catalog identifiers", () => {
    expect(toIdentifier("Jardim Iririú / Norte")).toBe("jardim-iririu-norte");
  });

  it("formats singular and plural count labels", () => {
    expect(formatCountLabel(1, "conexão", "conexões")).toBe("1 conexão");
    expect(formatCountLabel(0, "conexão", "conexões")).toBe("0 conexões");
    expect(formatCountLabel(2, "conexão", "conexões")).toBe("2 conexões");
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
