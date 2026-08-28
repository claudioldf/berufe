<script setup lang="ts">
import { fetchPublicSearchLocation } from "~/services/api/search-location";
import { useApiClient } from "~/services/api/client";
import { encodeSearchExpression } from "~/utils/searchExpression";
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

// `q` is the plain-text entry point the WebSite SearchAction JSON-LD points
// at (Google/answer engines expect a readable query param); `expressao` is
// the already base64url-encoded internal form. Prefer an explicit
// `expressao` if both are present.
const rawExpression = route.query.expressao;
const plainQuery = route.query.q;
const expressionQuery =
  rawExpression !== undefined
    ? { expressao: rawExpression }
    : typeof plainQuery === "string" && plainQuery.trim()
      ? { expressao: encodeSearchExpression(plainQuery) }
      : {};

await navigateTo(
  {
    path: searchLocationPath(location),
    query: expressionQuery,
  },
  { redirectCode: 302, replace: true },
);
</script>

<template>
  <main aria-busy="true" />
</template>
