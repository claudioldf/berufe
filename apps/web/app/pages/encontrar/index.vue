<script setup lang="ts">
import { fetchPublicSearchLocation } from "~/services/api/search-location";
import { useApiClient } from "~/services/api/client";
import {
  fallbackSearchLocation,
  searchLocationPath,
} from "~/utils/searchLocation";

const route = useRoute();
const client = useApiClient();
let location = fallbackSearchLocation;

try {
  location = (await fetchPublicSearchLocation(client)).location;
} catch {
  location = fallbackSearchLocation;
}

const expression = route.query.expressao;
await navigateTo(
  {
    path: searchLocationPath(location),
    query: expression === undefined ? {} : { expressao: expression },
  },
  { redirectCode: 302, replace: true },
);
</script>

<template>
  <main aria-busy="true" />
</template>
