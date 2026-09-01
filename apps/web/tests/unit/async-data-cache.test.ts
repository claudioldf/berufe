import { hydrationOnlyCachedData } from "@app/utils/asyncDataCache";

describe("async data cache policy", () => {
  it("uses SSR hydration data once but forces later client navigation to revalidate", () => {
    const payload = {
      data: { "public-professional-profile-ana-souza": { stale: true } },
    };

    expect(
      hydrationOnlyCachedData("public-professional-profile-ana-souza", {
        isHydrating: true,
        payload,
      }),
    ).toEqual({ stale: true });
    expect(
      hydrationOnlyCachedData("public-professional-profile-ana-souza", {
        isHydrating: false,
        payload,
      }),
    ).toBeUndefined();
  });
});
