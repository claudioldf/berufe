import { fetchFeaturedProfessionals } from "~/services/api/public-discovery";
import { useApiClient } from "~/services/api/client";

export function useFeaturedProfessionals() {
  const client = useApiClient();

  return useAsyncData("featured-public-professionals", () =>
    fetchFeaturedProfessionals(client),
  );
}
