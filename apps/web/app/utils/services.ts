import type { Service } from "~/types";
import { normalizeSearchText } from "~/utils/text";

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
