import type { Service } from "~/types";
import { normalizeSearchText } from "~/utils/text";

export interface ProfessionalServiceSelection {
  selectedServices: string[];
  primaryService: string;
}

export function normalizePrimaryService(
  selectedServices: string[],
  primaryService: string,
) {
  return selectedServices.includes(primaryService)
    ? primaryService
    : (selectedServices[0] ?? "");
}

export function toggleProfessionalService(
  selectedServices: string[],
  primaryService: string,
  name: string,
): ProfessionalServiceSelection {
  if (selectedServices.includes(name) && selectedServices.length === 1) {
    return {
      selectedServices: [...selectedServices],
      primaryService: normalizePrimaryService(selectedServices, primaryService),
    };
  }

  const nextServices = selectedServices.includes(name)
    ? selectedServices.filter((service) => service !== name)
    : [...selectedServices, name];

  return {
    selectedServices: nextServices,
    primaryService: normalizePrimaryService(nextServices, primaryService),
  };
}

export function findService(services: Service[], query: string) {
  const normalized = normalizeSearchText(query);
  if (!normalized) return undefined;
  return (
    services.find(
      (service) => normalizeSearchText(service.slug) === normalized,
    ) ??
    services.find(
      (service) => normalizeSearchText(service.name) === normalized,
    ) ??
    services.find((service) =>
      service.aliases.some(
        (alias) => normalizeSearchText(alias) === normalized,
      ),
    )
  );
}
