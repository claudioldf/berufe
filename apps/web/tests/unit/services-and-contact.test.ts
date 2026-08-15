import { describe, expect, it } from "vitest";
import catalogsData from "@data/catalogs.json";
import professionalsData from "@data/professionals.json";
import type { Neighborhood, Professional, Service } from "~/types";
import { buildWhatsAppUrl } from "~/utils/contact";
import { findService, professionalRelevance } from "~/utils/services";

const services = catalogsData.services as Service[];
const neighborhoods = catalogsData.neighborhoods as Neighborhood[];
const professionals = professionalsData as Professional[];

describe("service discovery", () => {
  it("matches slugs, names, accents, and aliases", () => {
    expect(findService(services, "eletricista")?.slug).toBe("eletricista");
    expect(findService(services, "Elétrica")?.slug).toBe("eletricista");
    expect(findService(services, "pintura")?.slug).toBe("pintor");
    expect(findService(services, "")).toBeUndefined();
  });

  it("prioritizes exact service and neighborhood evidence", () => {
    const service = findService(services, "eletricista")!;
    const neighborhood = neighborhoods.find((item) => item.code === "america")!;
    const scores = professionals.map((professional) =>
      professionalRelevance(professional, service, neighborhood),
    );
    expect(Math.max(...scores)).toBeGreaterThan(100);
  });
});

describe("contact links", () => {
  it("strips phone punctuation and encodes the message", () => {
    expect(buildWhatsAppUrl("+55 (47) 99999-1111", "Olá, tudo bem?")).toBe(
      "https://wa.me/5547999991111?text=Ol%C3%A1%2C%20tudo%20bem%3F",
    );
  });
});
