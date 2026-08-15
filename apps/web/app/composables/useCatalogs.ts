import { fetchPublicCatalog } from "~/services/api/catalog";
import { useApiClient } from "~/services/api/client";

export function useCatalogs() {
  const client = useApiClient();

  return useAsyncData("public-catalog", () => fetchPublicCatalog(client));
}
