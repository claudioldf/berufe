<script setup lang="ts">
import { computed } from "vue";
import type {
  PublicProfessionalCard,
  PublicServiceSuggestion,
  SearchLocation,
  StructuredSearchCity,
} from "~/types";
import { useCatalogs } from "~/composables/useCatalogs";
import { useProfessionalSearch } from "~/composables/useProfessionalSearch";
import { useToast } from "~/composables/useToast";
import {
  buildPublicProfileResultUrl,
  buildSearchResultWhatsAppUrl,
} from "~/utils/publicProfiles";
import { encodeSearchExpression } from "~/utils/searchExpression";
import {
  fallbackSearchLocation,
  findSearchLocationByRoute,
  searchLocationPath,
} from "~/utils/searchLocation";

const { showToast } = useToast();
const runtimeConfig = useRuntimeConfig();
const route = useRoute();
const router = useRouter();
const catalogResult = await useCatalogs();
if (catalogResult.error.value || !catalogResult.data.value) {
  throw createError({
    statusCode: 503,
    statusMessage: "Descoberta temporariamente indisponível.",
  });
}
const initialLocation = findSearchLocationByRoute(
  [...catalogResult.data.value.cities, fallbackSearchLocation],
  route.params.state_code,
  route.params.city,
);
if (!initialLocation) {
  throw createError({ statusCode: 404, statusMessage: "Cidade não atendida." });
}
const activeLocation = computed(
  () =>
    findSearchLocationByRoute(
      [...(catalogResult.data.value?.cities ?? []), fallbackSearchLocation],
      route.params.state_code,
      route.params.city,
    ) ?? initialLocation,
);
const professionalSearch = await useProfessionalSearch({
  location: activeLocation,
});
const {
  expressionInput,
  encodedExpression,
  hasSearchTerm,
  results,
  totalCount,
  interpretation,
  relatedServices,
  hasMoreResults,
  loadingMore,
  loadMoreResults,
  interaction,
  isSearching,
  isStructuredSearching,
  error: searchError,
  refresh,
  submitSearch,
  submitStructuredSearch,
} = professionalSearch;

const fallbackServices = computed(
  () => catalogResult.data.value?.services ?? [],
);
const fallbackCities = computed<StructuredSearchCity[]>(() => {
  return (catalogResult.data.value?.cities ?? []).map((location) => ({
    id: `${location.citySlug}-${location.stateSlug}`,
    name: location.city,
    stateCode: location.stateCode,
  }));
});

const interpretedServices = computed(
  () => interpretation.value?.services ?? [],
);
const primaryInterpretedService = computed(
  () => interpretedServices.value[0] ?? null,
);
const interpretedLocations = computed(() => {
  const labels = (interpretation.value?.locations ?? []).map(
    (location) => `${location.city} - ${location.stateCode}`,
  );
  return [...new Set(labels)];
});
const interpretedNeighborhoods = computed(() => [
  ...new Set(
    (interpretation.value?.locations ?? []).flatMap((location) =>
      location.neighborhood ? [location.neighborhood.name] : [],
    ),
  ),
]);

const isSearchRateLimited = computed(
  () => searchError.value?.code === "public_search_rate_limited",
);

const searchFailureMessage = computed(() => {
  const failure = searchError.value;
  if (!failure) return "";
  if (failure.code === "validation_failed") return failure.message;
  return "Não conseguimos interpretar sua busca agora. Tente novamente.";
});
const canRetrySearch = computed(() => {
  const failure = searchError.value;
  return failure?.code !== "validation_failed";
});

useSeoMeta({
  title: () => `Encontrar profissionais em ${activeLocation.value.city}`,
  description: () =>
    `Descreva o serviço que você precisa e encontre profissionais que atendem sua região em ${activeLocation.value.city}.`,
});

function profileUrl(professional: PublicProfessionalCard) {
  return buildPublicProfileResultUrl({
    slug: professional.slug,
    encodedExpression: encodedExpression.value,
    interactionToken: interaction.value?.token,
    requestMessage: interpretation.value?.normalizedRequest ?? undefined,
  });
}

function contactUrl(professional: PublicProfessionalCard) {
  return buildSearchResultWhatsAppUrl({
    apiBaseUrl: runtimeConfig.public.apiBaseUrl,
    professionalId: professional.id,
    interactionToken: interaction.value?.token,
    requestMessage: interpretation.value?.normalizedRequest ?? undefined,
  });
}

function relatedServiceUrl(service: PublicServiceSuggestion) {
  return {
    path: searchLocationPath(activeLocation.value),
    query: { expressao: encodeSearchExpression(service.name) },
  };
}

async function changeLocation(location: SearchLocation) {
  await router.push({
    path: searchLocationPath(location),
    query: route.query,
  });
}

function announceContact() {
  showToast({
    title: "Abrindo o WhatsApp",
    description: "O contato é direto com o profissional.",
  });
}

function retrySearch() {
  void refresh();
}
</script>

<template>
  <div class="finder">
    <section class="finder__masthead">
      <DesignSystemContainer class="finder__masthead-inner">
        <DesignSystemEyebrow>Profissionais</DesignSystemEyebrow>
        <h1>
          <template v-if="!hasSearchTerm">
            Encontre profissionais <em>em {{ activeLocation.city }}</em>
          </template>
          <template v-else-if="primaryInterpretedService">
            {{ primaryInterpretedService.name }}
            <em>em {{ activeLocation.city }}</em>
          </template>
          <template v-else
            >Encontre a ajuda certa
            <em>em {{ activeLocation.city }}</em></template
          >
        </h1>
        <p v-if="!hasSearchTerm">
          Descreva o serviço que precisa e inclua o bairro quando quiser refinar
          a busca.
        </p>
        <p v-else>
          {{
            primaryInterpretedService?.description ??
            "Conte o que precisa resolver e nós buscamos os serviços correspondentes."
          }}
        </p>
        <PublicExpressionSearch
          v-model="expressionInput"
          compact
          :location="activeLocation"
          :cities="catalogResult.data.value?.cities ?? []"
          location-source="manual"
          @submit="submitSearch"
          @location-change="changeLocation"
        />
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection class="finder__content">
      <DesignSystemContainer v-if="!hasSearchTerm">
        <PublicProfessionalSearchPrompt />
      </DesignSystemContainer>

      <DesignSystemContainer
        v-else
        class="finder__layout"
        :class="{ 'finder__layout--single': !interpretation }"
      >
        <aside
          v-if="interpretation"
          class="finder__aside"
          aria-label="Filtros interpretados"
        >
          <p>Filtros</p>
          <div class="filter-block">
            <strong>
              {{ interpretedServices.length === 1 ? "Serviço" : "Serviços" }}
            </strong>
            <template v-if="interpretedServices.length">
              <span v-for="service in interpretedServices" :key="service.id">
                {{ service.name }}
              </span>
            </template>
            <span v-else>Serviço não identificado</span>
          </div>
          <div class="filter-block">
            <strong>Localização</strong>
            <span v-for="location in interpretedLocations" :key="location">
              {{ location }}
            </span>
          </div>
          <div v-if="interpretedNeighborhoods.length" class="filter-block">
            <strong>
              {{ interpretedNeighborhoods.length === 1 ? "Bairro" : "Bairros" }}
            </strong>
            <span
              v-for="neighborhood in interpretedNeighborhoods"
              :key="neighborhood"
            >
              {{ neighborhood }}
            </span>
          </div>
          <div class="finder__explanation">
            <UIcon name="i-lucide-list-ordered" aria-hidden="true" />
            <strong>Como ordenamos</strong>
            <p>
              Primeiro, consideramos o serviço e o atendimento na região.
              Depois, avaliamos identidade verificada, portfólio e conexões
              profissionais.
            </p>
            <span>Relevância e qualidade.</span>
          </div>
        </aside>

        <div class="finder__results">
          <PublicSearchLoadingCard
            v-if="isSearching"
            :structured="isStructuredSearching"
          />

          <PublicSearchRateLimitCard
            v-else-if="isSearchRateLimited"
            :services="fallbackServices"
            :cities="fallbackCities"
            :loading="isStructuredSearching"
            @search="submitStructuredSearch"
          />

          <PublicSearchFailureCard
            v-else-if="searchFailureMessage"
            :message="searchFailureMessage"
            :services="fallbackServices"
            :cities="fallbackCities"
            :can-retry="canRetrySearch"
            :loading="isStructuredSearching"
            @retry="retrySearch"
            @search="submitStructuredSearch"
          />

          <template v-else>
            <div class="results-heading">
              <div>
                <strong>
                  {{ totalCount }}
                  {{
                    totalCount === 1
                      ? "profissional encontrado"
                      : "profissionais encontrados"
                  }}
                </strong>
                <span v-if="interpretedNeighborhoods.length === 1">
                  Atendendo {{ interpretedNeighborhoods[0] }}
                </span>
                <span v-else-if="interpretedNeighborhoods.length > 1">
                  Atendendo os bairros informados
                </span>
                <span v-else>Em {{ activeLocation.city }}</span>
              </div>
              <span class="results-heading__order">
                <UIcon name="i-lucide-info" /> Ordem por relevância
              </span>
            </div>

            <div v-if="results.length" class="results-list">
              <PublicProfessionalCard
                v-for="professional in results"
                :key="professional.id"
                :professional="professional"
                :profile-url="profileUrl(professional)"
                :contact-url="contactUrl(professional)"
                @contact="announceContact"
              />
            </div>

            <div v-if="hasMoreResults" class="results-more">
              <UButton
                color="neutral"
                variant="outline"
                :loading="loadingMore"
                @click="loadMoreResults"
              >
                Carregar mais profissionais
              </UButton>
              <p aria-live="polite">
                Mostrando {{ results.length }} de {{ totalCount }}.
              </p>
            </div>

            <DesignSystemSurfaceCard
              v-if="!results.length"
              class="empty-results"
            >
              <span class="empty-results__icon">
                <UIcon name="i-lucide-search-x" />
              </span>
              <h2>Não encontramos um<br />profissional na sua região.</h2>
              <p>
                Tente buscar em outra região próxima ou por outro serviço de que
                precise.
              </p>
              <div
                v-if="relatedServices.length"
                class="empty-results__suggestions"
              >
                <NuxtLink
                  v-for="service in relatedServices"
                  :key="service.id"
                  :to="relatedServiceUrl(service)"
                >
                  <UIcon :name="service.icon" aria-hidden="true" />
                  {{ service.name }}
                </NuxtLink>
              </div>
            </DesignSystemSurfaceCard>

            <div class="finder__principle">
              <UIcon name="i-lucide-heart-handshake" />
              <div>
                <strong>Você decide com quem falar.</strong>
                <p>Na Berufe, seu contato só chega a quem você escolher.</p>
              </div>
            </div>
          </template>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>
  </div>
</template>

<style scoped lang="scss">
.finder {
  &__masthead {
    padding: 40px 0 44px;
    background: #dff1eb;
  }

  &__masthead h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.4rem, 5vw, 4.5rem);
    font-weight: 500;
    letter-spacing: -0.045em;
    line-height: 1;
  }

  &__masthead h1 em {
    color: var(--color-brand);
    font-weight: inherit;
  }

  &__masthead-inner > p {
    max-width: 720px;
    margin: 15px 0 26px;
    color: var(--ink-soft);
    line-height: 1.65;
  }

  &__layout {
    display: grid;
    grid-template-columns: 230px minmax(0, 1fr);
    gap: 42px;
  }

  &__layout--single {
    grid-template-columns: minmax(0, 980px);
    justify-content: center;
  }

  &__aside {
    position: sticky;
    top: 24px;
    align-self: start;
  }

  &__aside > p {
    margin: 0 0 14px;
    font-size: 0.82rem;
    font-weight: 900;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }

  &__results {
    min-width: 0;
  }

  &__explanation {
    margin-top: 20px;
    padding: 18px;
    border-radius: 17px;
    background: var(--color-brand-tint-muted);
  }

  &__explanation > svg {
    margin-bottom: 11px;
    color: var(--color-brand);
    font-size: 1.3rem;
  }

  &__explanation strong {
    display: block;
    font-size: 0.84rem;
  }

  &__explanation p {
    margin: 7px 0 10px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }

  &__explanation span {
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 800;
  }

  &__principle {
    display: flex;
    align-items: center;
    gap: 13px;
    margin-top: 18px;
    padding: 17px;
    border: 1px dashed #aacbbf;
    border-radius: 16px;
    color: var(--color-brand);
  }

  &__principle > svg {
    font-size: 1.5rem;
  }

  &__principle strong {
    display: block;
    font-size: 0.86rem;
  }

  &__principle p {
    margin: 3px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
}

.filter-block {
  display: grid;
  gap: 5px;
  padding: 15px 0;
  border-top: 1px solid var(--line);
}

.filter-block strong {
  font-size: 0.82rem;
}

.filter-block span {
  color: var(--ink-soft);
  font-size: 0.84rem;
}

.results-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 18px;
}

.results-heading strong,
.results-heading span {
  display: block;
}

.results-heading strong {
  font-family: var(--font-display);
  font-size: 1.35rem;
}

.results-heading > div span {
  margin-top: 4px;
  color: var(--ink-soft);
  font-size: 0.82rem;
}

.results-heading__order {
  display: flex !important;
  align-items: center;
  gap: 5px;
  color: var(--color-brand);
  font-size: 0.86rem;
  font-weight: 800;
}

.results-list {
  display: grid;
  gap: 14px;
}

.results-more {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  margin-top: 16px;
}

.results-more p {
  margin: 0;
  color: var(--ink-soft);
  font-size: 0.82rem;
}

.empty-results {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 30px;
}

.empty-results {
  display: grid;
  justify-items: center;
  padding: 56px 30px;
  text-align: center;
}

.empty-results__icon {
  display: grid;
  place-items: center;
  width: 58px;
  height: 58px;
  border-radius: 18px;
  background: var(--mint);
  color: var(--color-brand);
  font-size: 1.5rem;
}

.empty-results h2 {
  margin: 18px 0 7px;
  font-family: var(--font-display);
  font-size: 2rem;
}

.empty-results p {
  max-width: 520px;
  margin: 0;
  color: var(--ink-soft);
  font-size: 0.83rem;
  line-height: 1.6;
}

.empty-results__suggestions {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  margin-top: 22px;
}

.empty-results__suggestions a {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 9px 12px;
  border: 1px solid var(--line);
  border-radius: 11px;
  color: var(--ink);
  font-size: 0.84rem;
  font-weight: 800;
  text-decoration: none;
}

@media (width <= 800px) {
  .finder {
    &__layout {
      grid-template-columns: minmax(0, 1fr);
    }

    &__aside {
      display: none;
    }

    &__content {
      padding-top: 42px;
    }
  }
}

@media (width <= 520px) {
  .results-heading {
    &__order {
      display: none !important;
    }
  }
}
</style>
