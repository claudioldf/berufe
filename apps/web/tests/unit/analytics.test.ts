import {
  analyticsPageLocation,
  analyticsPagePath,
  analyticsSearchTerm,
  createAnalyticsPageViewTracker,
  googleTagManagerHead,
  isGoogleTagManagerContainerId,
} from "@app/utils/analytics";

describe("Google Tag Manager bootstrap", () => {
  afterEach(() => {
    Reflect.deleteProperty(window, "dataLayer");
    Reflect.deleteProperty(window, "gtag");
  });

  it("accepts only well-formed web container IDs", () => {
    expect(isGoogleTagManagerContainerId("GTM-PBP8MFLG")).toBe(true);
    expect(isGoogleTagManagerContainerId("G-K8GG56FD41")).toBe(false);
    expect(isGoogleTagManagerContainerId("GTM-<script>")).toBe(false);
    expect(isGoogleTagManagerContainerId(undefined)).toBe(false);
  });

  it("renders consent before the GTM loader and the fallback at body open", () => {
    const head = googleTagManagerHead("GTM-PBP8MFLG");

    expect(head.script.map(({ key }) => key)).toEqual([
      "google-consent-mode",
      "google-tag-manager",
    ]);
    expect(head.script[0]?.innerHTML).toContain(
      'window.gtag("consent","default"',
    );
    expect(head.script[1]?.innerHTML).toContain(
      "googletagmanager.com/gtm.js?id=",
    );
    expect(head.script[1]?.innerHTML).toContain("GTM-PBP8MFLG");
    expect(head.noscript).toEqual([
      {
        key: "google-tag-manager-noscript",
        innerHTML:
          '<iframe src="https://www.googletagmanager.com/ns.html?id=GTM-PBP8MFLG" height="0" width="0" style="display:none;visibility:hidden"></iframe>',
        tagPosition: "bodyOpen",
      },
    ]);
  });

  it("uses the real arguments object for consent commands", () => {
    const head = googleTagManagerHead("GTM-PBP8MFLG");

    new Function(head.script[0]?.innerHTML ?? "")();

    expect(window.dataLayer).toHaveLength(1);
    expect(Array.isArray(window.dataLayer[0])).toBe(false);
    expect(Array.from(window.dataLayer[0] as ArrayLike<unknown>)).toEqual([
      "consent",
      "default",
      {
        ad_storage: "denied",
        ad_user_data: "denied",
        ad_personalization: "denied",
        analytics_storage: "granted",
      },
    ]);
  });

  it("rejects an invalid container ID before rendering inline HTML", () => {
    expect(() => googleTagManagerHead('GTM-x"</script>')).toThrow(TypeError);
  });
});

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

describe("analyticsPageLocation", () => {
  it("returns an absolute URL without query strings or fragments", () => {
    expect(
      analyticsPageLocation(
        "/servicos/eletricista?utm_source=google#results",
        "https://www.berufe.com.br",
      ),
    ).toBe("https://www.berufe.com.br/servicos/eletricista");
  });

  it("redacts bearer tokens from the absolute URL", () => {
    expect(
      analyticsPageLocation(
        "/orcamento/secret-token?utm_source=whatsapp",
        "https://www.berufe.com.br",
      ),
    ).toBe("https://www.berufe.com.br/orcamento/[token]");
  });
});

describe("createAnalyticsPageViewTracker", () => {
  it("dispatches one page view per distinct sanitized route", () => {
    const dispatch = vi.fn();
    let fullPath = "/";
    let pageTitle = "Início · Berufe";
    const trackPageView = createAnalyticsPageViewTracker({
      dispatch,
      getFullPath: () => fullPath,
      getOrigin: () => "https://www.berufe.com.br",
      getPageTitle: () => pageTitle,
    });

    trackPageView();
    trackPageView();
    fullPath = "/?utm_source=google";
    trackPageView();

    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(dispatch).toHaveBeenLastCalledWith("event", "page_view", {
      page_location: "https://www.berufe.com.br/",
      page_path: "/",
      page_title: "Início · Berufe",
    });

    fullPath = "/servicos/eletricista";
    pageTitle = "Eletricistas · Berufe";
    trackPageView();

    expect(dispatch).toHaveBeenCalledTimes(2);
    expect(dispatch).toHaveBeenLastCalledWith("event", "page_view", {
      page_location: "https://www.berufe.com.br/servicos/eletricista",
      page_path: "/servicos/eletricista",
      page_title: "Eletricistas · Berufe",
    });
  });

  it("never dispatches a bearer token in page-view parameters", () => {
    const dispatch = vi.fn();
    const trackPageView = createAnalyticsPageViewTracker({
      dispatch,
      getFullPath: () => "/recomendacao/private-token?source=whatsapp",
      getOrigin: () => "https://www.berufe.com.br",
      getPageTitle: () => "Recomendação · Berufe",
    });

    trackPageView();

    expect(JSON.stringify(dispatch.mock.calls)).not.toContain("private-token");
    expect(dispatch).toHaveBeenCalledWith("event", "page_view", {
      page_location: "https://www.berufe.com.br/recomendacao/[token]",
      page_path: "/recomendacao/[token]",
      page_title: "Recomendação · Berufe",
    });
  });
});

describe("analyticsSearchTerm", () => {
  it("joins the matched service and city", () => {
    expect(analyticsSearchTerm(["Eletricista"], "Joinville")).toBe(
      "Eletricista - Joinville",
    );
  });

  it("uses only the first matched service", () => {
    expect(analyticsSearchTerm(["Eletricista", "Encanador"], "Joinville")).toBe(
      "Eletricista - Joinville",
    );
  });

  it("falls back to the service alone when there is no city", () => {
    expect(analyticsSearchTerm(["Eletricista"], null)).toBe("Eletricista");
  });

  it("falls back to the city alone when no service matched", () => {
    expect(analyticsSearchTerm([], "Joinville")).toBe("Joinville");
  });

  it("returns an empty string when neither is available", () => {
    expect(analyticsSearchTerm([], undefined)).toBe("");
  });
});
