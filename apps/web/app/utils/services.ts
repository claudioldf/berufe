import type { Neighborhood, Professional, Service } from "~/types";
import { normalizeSearchText } from "~/utils/text";

export function findService(services: Service[], query: string) {
  const normalized = normalizeSearchText(query);
  if (!normalized) return undefined;
  return (
    services.find((service) => service.slug === normalized) ??
    services.find(
      (service) => normalizeSearchText(service.name) === normalized,
    ) ??
    services.find((service) =>
      service.aliases.some((alias) => {
        const normalizedAlias = normalizeSearchText(alias);
        return (
          normalizedAlias === normalized ||
          normalizedAlias.includes(normalized) ||
          normalized.includes(normalizedAlias)
        );
      }),
    )
  );
}

export function professionalRelevance(
  professional: Professional,
  service: Service,
  neighborhood?: Neighborhood,
) {
  let score = 0;
  if (professional.primaryService === service.name) score += 100;
  if (
    neighborhood?.code !== "all" &&
    professional.neighborhoods.includes(neighborhood?.name ?? "")
  ) {
    score += 50;
  }
  if (
    professional.evidence.some((item) => item.label === "Identidade verificada")
  ) {
    score += 25;
  }
  if (professional.portfolio.length) score += 10;
  return score + professional.relationships.length;
}
