import { mockNuxtImport, mountSuspended } from "@nuxt/test-utils/runtime";
import LegacyFinderPage from "@app/pages/encontrar/index.vue";
import { fallbackSearchLocation } from "@app/utils/searchLocation";
import { encodeSearchExpression } from "@app/utils/searchExpression";

const mocks = vi.hoisted(() => ({
  client: {},
  fetchLocation: vi.fn(),
  navigateTo: vi.fn(),
}));

mockNuxtImport("navigateTo", () => mocks.navigateTo);
vi.mock("@app/services/api/client", () => ({
  useApiClient: () => mocks.client,
}));
vi.mock("@app/services/api/search-location", () => ({
  fetchPublicSearchLocation: mocks.fetchLocation,
}));

describe("legacy finder redirect", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.navigateTo.mockResolvedValue(undefined);
  });

  it("resolves the effective city and preserves the encoded expression", async () => {
    const expression = encodeSearchExpression("Preciso de eletricista");
    mocks.fetchLocation.mockResolvedValue({
      location: fallbackSearchLocation,
      source: "ip",
    });

    await mountSuspended(LegacyFinderPage, {
      shallow: true,
      route: `/encontrar?expressao=${expression}`,
    });

    expect(mocks.fetchLocation).toHaveBeenCalledWith(mocks.client);
    expect(mocks.navigateTo).toHaveBeenCalledWith(
      {
        path: "/encontrar/sc/joinville",
        query: { expressao: expression },
      },
      { redirectCode: 302, replace: true },
    );
  });

  it("uses the visible launch-city fallback when resolution fails", async () => {
    mocks.fetchLocation.mockRejectedValue(new Error("provider unavailable"));

    await mountSuspended(LegacyFinderPage, {
      shallow: true,
      route: "/encontrar",
    });

    expect(mocks.navigateTo).toHaveBeenCalledWith(
      { path: "/encontrar/sc/joinville", query: {} },
      { redirectCode: 302, replace: true },
    );
  });
});
