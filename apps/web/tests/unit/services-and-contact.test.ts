import { describe, expect, it } from "vitest";
import catalogsData from "@data/catalogs.json";
import type { Service } from "~/types";
import { buildWhatsAppUrl } from "~/utils/contact";
import {
  findService,
  normalizePrimaryService,
  toggleProfessionalService,
} from "~/utils/services";

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

describe("professional service selection", () => {
  it("uses the first selection when the featured service is missing", () => {
    expect(normalizePrimaryService(["Eletricista", "Diarista"], "")).toBe(
      "Eletricista",
    );
    expect(
      normalizePrimaryService(
        ["Eletricista", "Diarista"],
        "Serviço indisponível",
      ),
    ).toBe("Eletricista");
  });

  it("reassigns a removed featured service and keeps the final selection", () => {
    expect(
      toggleProfessionalService(
        ["Eletricista", "Diarista"],
        "Eletricista",
        "Eletricista",
      ),
    ).toEqual({
      selectedServices: ["Diarista"],
      primaryService: "Diarista",
    });
    expect(
      toggleProfessionalService(["Diarista"], "Diarista", "Diarista"),
    ).toEqual({
      selectedServices: ["Diarista"],
      primaryService: "Diarista",
    });
  });
});

describe("contact links", () => {
  it("strips phone punctuation and encodes the message", () => {
    expect(buildWhatsAppUrl("+55 (47) 99999-1111", "Olá, tudo bem?")).toBe(
      "https://wa.me/5547999991111?text=Ol%C3%A1%2C%20tudo%20bem%3F",
    );
  });
});
