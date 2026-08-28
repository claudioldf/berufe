import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchLocationCities,
  fetchLocationNeighborhoods,
  fetchLocationStates,
} from "@app/services/api/locations";

function apiClientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("locations API", () => {
  it("maps the IBGE hierarchy and sends stable codes through generated routes", async () => {
    const statesClient = apiClientReturning({
      data: {
        data: [{ code: "42", abbreviation: "SC", name: "Santa Catarina" }],
        request_id: "locations-states",
      },
      error: undefined,
      response: new Response(null),
    });
    const citiesClient = apiClientReturning({
      data: {
        data: [
          {
            code: "4209102",
            name: "Joinville",
            slug: "joinville",
            state_code: "42",
            state_abbreviation: "SC",
            state_name: "Santa Catarina",
          },
        ],
        request_id: "locations-cities",
      },
      error: undefined,
      response: new Response(null),
    });
    const neighborhoodsClient = apiClientReturning({
      data: {
        data: [
          {
            code: "4209102007",
            city_code: "4209102",
            name: "América",
          },
        ],
        request_id: "locations-neighborhoods",
      },
      error: undefined,
      response: new Response(null),
    });

    await expect(fetchLocationStates(statesClient)).resolves.toEqual([
      { code: "42", abbreviation: "SC", name: "Santa Catarina" },
    ]);
    await expect(fetchLocationCities(citiesClient, "SC")).resolves.toEqual([
      {
        code: "4209102",
        name: "Joinville",
        slug: "joinville",
        stateCode: "42",
        stateAbbreviation: "SC",
        stateName: "Santa Catarina",
      },
    ]);
    await expect(
      fetchLocationNeighborhoods(neighborhoodsClient, "4209102"),
    ).resolves.toEqual([
      { code: "4209102007", cityCode: "4209102", name: "América" },
    ]);

    expect(statesClient.GET).toHaveBeenCalledWith("/api/v1/locations/states");
    expect(citiesClient.GET).toHaveBeenCalledWith(
      "/api/v1/locations/states/{state_abbreviation}/cities",
      { params: { path: { state_abbreviation: "SC" } } },
    );
    expect(neighborhoodsClient.GET).toHaveBeenCalledWith(
      "/api/v1/locations/cities/{city_code}/neighborhoods",
      { params: { path: { city_code: "4209102" } } },
    );
  });
});
