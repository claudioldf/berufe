<script setup lang="ts">
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import { resolveSharedQuote } from "~/services/api/shared-quotes";

const route = useRoute();
const client = useApiClient();
const token = computed(() =>
  Array.isArray(route.params.token)
    ? (route.params.token[0] ?? "")
    : String(route.params.token ?? ""),
);
const resolved = await useAsyncData(
  "shared-quote-resolve",
  async () => {
    try {
      return {
        kind: "success" as const,
        value: await resolveSharedQuote(client, token.value),
      };
    } catch (error) {
      return {
        kind: "error" as const,
        notFound:
          error instanceof ApiRequestError && error.code === "not_found",
      };
    }
  },
  { watch: [token] },
);
const outcome = resolved.data.value;
if (!outcome || outcome.kind === "error") {
  throw createError({
    statusCode: outcome?.notFound ? 404 : 503,
    statusMessage: outcome?.notFound
      ? "Orçamento não encontrado"
      : "Orçamento temporariamente indisponível",
  });
}
const quote = computed(() => outcome.value.quote);
const professional = computed(() => outcome.value.professional);

useSeoMeta({
  title: `Orçamento #${quote.value.number}`,
  robots: "noindex, nofollow",
});

function printQuote() {
  if (import.meta.client) window.print();
}
</script>

<template>
  <div class="shared-quote-page">
    <DesignSystemContainer as="header" class="shared-quote-page__header"
      ><DesignSystemBrand size="sm" />
      <div>
        <UIcon name="i-lucide-lock-keyhole" /> Link privado do orçamento
      </div></DesignSystemContainer
    >
    <DesignSystemContainer class="shared-quote-page__content">
      <div class="shared-quote-page__heading">
        <div>
          <p>Olá, {{ quote.customerName }}.</p>
          <h1>Aqui está seu orçamento.</h1>
          <span
            >Revise os itens e converse diretamente com
            {{ professional.name.split(" ")[0] }} se tiver alguma dúvida.</span
          >
        </div>
        <UButton
          color="neutral"
          variant="outline"
          icon="i-lucide-printer"
          @click="printQuote"
          >Imprimir</UButton
        >
      </div>
      <QuotesQuotePreview
        :quote="quote"
        :professional="professional"
        customer-facing
        authoritative-totals
      />
      <p class="shared-quote-page__notice">
        <UIcon name="i-lucide-info" /> Este link permite visualizar o orçamento,
        mas não representa aceite, assinatura ou pagamento.
      </p>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.shared-quote-page {
  min-height: 100vh;
  padding-bottom: 70px;
  background: #eeeae1;
  &__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    min-height: 70px;
  }
  &__header > div {
    display: flex;
    align-items: center;
    gap: 5px;
    color: var(--ink-soft);
    font-size: 0.84rem;
    font-weight: 750;
  }
  &__content {
    max-width: 760px;
  }
  &__heading {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 20px;
    margin: 42px 0 24px;
  }
  &__heading p {
    margin: 0 0 6px;
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 850;
  }
  &__heading h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2.5rem;
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  &__heading span {
    display: block;
    max-width: 500px;
    margin-top: 7px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }
  &__notice {
    display: flex;
    align-items: flex-start;
    justify-content: center;
    gap: 5px;
    margin: 16px 0 0;
    color: var(--ink-soft);
    font-size: 0.84rem;
    text-align: center;
  }
}
@media (width <= 600px) {
  .shared-quote-page {
    &__heading {
      display: grid;
    }
    &__heading h1 {
      font-size: 2rem;
    }
  }
}
@media print {
  .shared-quote-page {
    &__header,
    &__heading,
    &__notice {
      display: none;
    }
    padding: 0;
    background: white;
    &__content {
      width: 100%;
      max-width: none;
    }
  }
}
</style>
