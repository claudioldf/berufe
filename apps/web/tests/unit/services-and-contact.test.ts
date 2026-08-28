import { describe, expect, it } from "vitest";
import catalogsData from "@data/catalogs.json";
import type { Service } from "~/types";
import { buildWhatsAppUrl } from "~/utils/contact";
import { findService } from "~/utils/services";

const services = catalogsData.services as Service[];

describe("service discovery", () => {
  it("matches slugs, names, accents, and aliases", () => {
    expect(findService(services, "eletricista")?.slug).toBe("eletricista");
    expect(findService(services, "Elétrica")?.slug).toBe("eletricista");
    expect(findService(services, "pintura")?.slug).toBe("pintor");
    expect(findService(services, "")).toBeUndefined();
  });

  it("keeps legacy catalog terms searchable after the display-copy update", () => {
    expect(findService(services, "marido de aluguel")?.name).toBe(
      "Pequenos reparos",
    );
    expect(findService(services, "desentupidor")?.name).toBe("Desentupimento");
    expect(findService(services, "petsitter")?.name).toBe("Cuidados para pets");
  });
});

describe("contact links", () => {
  it("strips phone punctuation and encodes the message", () => {
    expect(buildWhatsAppUrl("+55 (47) 99999-1111", "Olá, tudo bem?")).toBe(
      "https://wa.me/5547999991111?text=Ol%C3%A1%2C%20tudo%20bem%3F",
    );
  });
});
