import type { SearchLocation } from "~/types";

export const fallbackSearchLocation: SearchLocation = {
  cityCode: "4209102",
  stateCode: "SC",
  city: "Joinville",
  stateSlug: "sc",
  citySlug: "joinville",
};

export function searchLocationPath(location: SearchLocation) {
  return `/encontrar/${location.stateSlug}/${location.citySlug}`;
}

export function findSearchLocationByRoute(
  locations: SearchLocation[],
  stateSlug: unknown,
  citySlug: unknown,
) {
  const normalizedState = String(
    Array.isArray(stateSlug) ? (stateSlug[0] ?? "") : (stateSlug ?? ""),
  ).toLowerCase();
  const normalizedCity = String(
    Array.isArray(citySlug) ? (citySlug[0] ?? "") : (citySlug ?? ""),
  ).toLowerCase();

  return (
    locations.find(
      (location) =>
        location.stateSlug === normalizedState &&
        location.citySlug === normalizedCity,
    ) ?? null
  );
}
