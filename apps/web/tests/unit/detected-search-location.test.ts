import { useDetectedSearchLocation } from "@app/composables/useDetectedSearchLocation";
import { fallbackSearchLocation } from "@app/utils/searchLocation";

const mocks = vi.hoisted(() => ({
  client: {},
  fetchLocation: vi.fn(),
}));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => mocks.client,
}));
vi.mock("@app/services/api/search-location", () => ({
  fetchPublicSearchLocation: mocks.fetchLocation,
}));

describe("detected search location", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("publishes the server-resolved source and lets a manual choice win", async () => {
    mocks.fetchLocation.mockResolvedValue({
      location: fallbackSearchLocation,
      source: "ip",
    });
    const detected = useDetectedSearchLocation();

    await detected.resolve();

    expect(detected.location.value).toEqual(fallbackSearchLocation);
    expect(detected.source.value).toBe("ip");

    detected.select(fallbackSearchLocation);
    expect(detected.source.value).toBe("manual");
  });

  it("keeps the visible launch-city fallback when resolution fails", async () => {
    mocks.fetchLocation.mockRejectedValue(new Error("provider unavailable"));
    const detected = useDetectedSearchLocation();

    await detected.resolve();

    expect(detected.location.value).toEqual(fallbackSearchLocation);
    expect(detected.source.value).toBe("fallback");
    expect(detected.resolving.value).toBe(false);
  });
});
