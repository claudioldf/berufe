<script setup lang="ts">
import { fetchPublicSearchLocation } from "~/services/api/search-location";
import { useApiClient } from "~/services/api/client";
import {
  encodeSearchExpression,
  searchExpressionQuery,
} from "~/utils/searchExpression";
import { matchSearchAction } from "~/utils/search-actions";
import {
  fallbackSearchLocation,
  searchLocationPath,
} from "~/utils/searchLocation";

const route = useRoute();
const client = useApiClient();
let location = fallbackSearchLocation;

// Account actions ("excluir conta", "cadastro") are answered by a help page,
// not by a service search. The session is unknown here, so the help page's
// call to action covers signed-in professionals.
const searchedAction = matchSearchAction(
  typeof route.query.q === "string" ? route.query.q : undefined,
);
if (searchedAction) {
  await navigateTo(searchedAction.helpPath, {
    redirectCode: 302,
    replace: true,
  });
} else {
  try {
    location = (await fetchPublicSearchLocation(client)).location;
  } catch {
    location = fallbackSearchLocation;
  }

  // `q` is plain text only on this SearchAction entry point. City search URLs
  // use the same key with the base64url-encoded route state. `expressao` remains
  // accepted here solely to keep previously shared links working.
  const plainQuery = route.query.q;
  const legacyExpression = route.query.expressao;
  const expressionQuery =
    typeof plainQuery === "string" && plainQuery.trim()
      ? searchExpressionQuery(encodeSearchExpression(plainQuery))
      : typeof legacyExpression === "string" && legacyExpression
        ? searchExpressionQuery(legacyExpression)
        : {};

  await navigateTo(
    {
      path: searchLocationPath(location),
      query: expressionQuery,
    },
    { redirectCode: 302, replace: true },
  );
}
</script>

<template>
  <main aria-busy="true" />
</template>
