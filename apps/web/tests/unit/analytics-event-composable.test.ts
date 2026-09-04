import { useAnalyticsEvent } from "@app/composables/useAnalyticsEvent";

describe("useAnalyticsEvent", () => {
  afterEach(() => {
    Reflect.deleteProperty(window, "gtag");
  });

  it("forwards the event name and params to the global gtag", () => {
    const gtag = vi.fn();
    window.gtag = gtag;

    useAnalyticsEvent().trackEvent("generate_lead", {
      method: "whatsapp",
      source: "public_profile",
    });

    expect(gtag).toHaveBeenCalledWith("event", "generate_lead", {
      method: "whatsapp",
      source: "public_profile",
    });
  });

  it("does nothing when GA is disabled (no global gtag)", () => {
    expect(() => useAnalyticsEvent().trackEvent("generate_lead")).not.toThrow();
  });
});
