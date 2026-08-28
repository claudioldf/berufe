import { useFinderSearchLocation } from "@app/composables/useFinderSearchLocation";

const mocks = vi.hoisted(() => ({
  client: {},
  fetchCities: vi.fn(),
}));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => mocks.client,
}));
vi.mock("@app/services/api/locations", () => ({
  fetchLocationCities: mocks.fetchCities,
}));

describe("finder search location", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("resolves a valid IBGE route even when the city has no public professionals", async () => {
    mocks.fetchCities.mockResolvedValue([
      {
        code: "4106902",
        name: "Curitiba",
        slug: "curitiba",
        stateCode: "41",
        stateAbbreviation: "PR",
        stateName: "Paraná",
      },
    ]);
    await useRouter().replace("/encontrar/pr/curitiba");

    const finderLocation = await useFinderSearchLocation({
      catalogLocations: [],
    });

    expect(finderLocation.location.value).toEqual({
      cityCode: "4106902",
      stateCode: "PR",
      city: "Curitiba",
      stateSlug: "pr",
      citySlug: "curitiba",
    });
    expect(mocks.fetchCities).toHaveBeenCalledWith(mocks.client, "PR");
  });
});
