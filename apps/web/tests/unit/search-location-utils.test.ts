import {
  fallbackSearchLocation,
  findSearchLocationByRoute,
  searchLocationPath,
} from "@app/utils/searchLocation";

describe("search location route utilities", () => {
  it("builds and resolves the canonical supported-city path case-insensitively", () => {
    expect(searchLocationPath(fallbackSearchLocation)).toBe(
      "/encontrar/sc/joinville",
    );
    expect(
      findSearchLocationByRoute([fallbackSearchLocation], "SC", "JOINVILLE"),
    ).toEqual(fallbackSearchLocation);
  });

  it("does not silently accept an unsupported route", () => {
    expect(
      findSearchLocationByRoute([fallbackSearchLocation], "sp", "sao-paulo"),
    ).toBeNull();
  });
});
