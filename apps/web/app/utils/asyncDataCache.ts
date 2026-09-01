interface HydrationPayload {
  isHydrating?: boolean;
  payload: { data: Record<string, unknown> };
}

export function hydrationOnlyCachedData<T>(
  key: string,
  nuxtApp: HydrationPayload,
): T | undefined {
  return nuxtApp.isHydrating
    ? (nuxtApp.payload.data[key] as T | undefined)
    : undefined;
}
