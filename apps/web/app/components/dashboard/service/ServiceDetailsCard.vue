<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalServiceJob } from "~/types";
import { formatDate } from "~/utils/formatters";

const props = defineProps<{
  quote: ProfessionalServiceJob["quote"];
}>();

const phoneHref = computed(
  () => `tel:${props.quote.customerPhone.replace(/\D/g, "")}`,
);
const emailHref = computed(() => `mailto:${props.quote.customerEmail}`);
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="details-card"
    aria-labelledby="service-details-title"
  >
    <header class="details-card__header">
      <span class="details-card__kicker">Informações</span>
      <h2 id="service-details-title">Detalhes do atendimento</h2>
      <p>Os dados combinados no orçamento aprovado.</p>
    </header>

    <dl class="details-card__list">
      <div class="details-card__item">
        <span class="details-card__icon" aria-hidden="true">
          <UIcon name="i-lucide-clock-3" />
        </span>
        <div>
          <dt>Data combinada</dt>
          <dd>
            {{
              quote.scheduledOn
                ? formatDate(quote.scheduledOn)
                : "Ainda não informada"
            }}
          </dd>
        </div>
      </div>

      <div class="details-card__item">
        <span class="details-card__icon" aria-hidden="true">
          <UIcon name="i-lucide-map-pin" />
        </span>
        <div>
          <dt>Local do serviço</dt>
          <dd>{{ quote.serviceAddress || "Endereço não informado" }}</dd>
        </div>
      </div>

      <div class="details-card__item">
        <span class="details-card__icon" aria-hidden="true">
          <UIcon name="i-lucide-user-round" />
        </span>
        <div>
          <dt>Contato do cliente</dt>
          <dd>
            <a :href="phoneHref">{{ quote.customerPhone }}</a>
            <a v-if="quote.customerEmail" :href="emailHref">
              {{ quote.customerEmail }}
            </a>
            <span v-else>E-mail não informado</span>
          </dd>
        </div>
      </div>
    </dl>

    <footer class="details-card__footer">
      <span class="details-card__quote-reference">
        <UIcon name="i-lucide-file-check-2" aria-hidden="true" />
        Dados registrados no orçamento #{{ quote.number }}
      </span>
      <NuxtLink
        class="details-card__quote-link"
        :to="`/app/professional/quotes/new?quote=${quote.id}`"
        :aria-label="`Abrir orçamento #${quote.number}`"
      >
        Ver orçamento
        <UIcon name="i-lucide-arrow-up-right" aria-hidden="true" />
      </NuxtLink>
    </footer>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.details-card {
  overflow: hidden;
  background: rgb(255 255 255 / 88%);

  &__header {
    padding: 27px 28px 22px;
    border-bottom: 1px solid var(--line);
  }

  &__kicker {
    color: var(--color-brand);
    font-size: 0.7rem;
    font-weight: 850;
    letter-spacing: 0.12em;
    text-transform: uppercase;
  }

  &__header h2 {
    margin: 5px 0 4px;
    font-family: var(--font-display);
    font-size: 1.72rem;
    font-weight: 600;
    letter-spacing: -0.03em;
  }

  &__header p {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.88rem;
  }

  &__list {
    display: grid;
    margin: 0;
  }

  &__item {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 15px;
    align-items: start;
    padding: 20px 28px;
  }

  &__item + &__item {
    border-top: 1px solid var(--line);
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 38px;
    height: 38px;
    border-radius: 12px;
    background: var(--color-brand-tint-subtle);
    color: var(--color-brand);
    font-size: 1.05rem;
  }

  &__item dt {
    margin-bottom: 4px;
    color: var(--color-text-subtle);
    font-size: 0.7rem;
    font-weight: 800;
    letter-spacing: 0.07em;
    text-transform: uppercase;
  }

  &__item dd {
    display: grid;
    gap: 3px;
    margin: 0;
    font-size: 0.92rem;
    font-weight: 700;
    line-height: 1.45;
  }

  &__item a {
    justify-self: start;
    color: var(--ink);
    text-decoration: none;
  }

  &__item a + a,
  &__item dd > span {
    color: var(--ink-soft);
    font-size: 0.84rem;
    font-weight: 500;
  }

  &__item a:hover {
    color: var(--color-brand);
    text-decoration: underline;
    text-underline-offset: 3px;
  }

  &__footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
    padding: 13px 28px;
    border-top: 1px solid var(--line);
    background: var(--color-surface-neutral);
    color: var(--color-text-muted);
    font-size: 0.75rem;
  }

  &__quote-reference,
  &__quote-link {
    display: inline-flex;
    align-items: center;
    gap: 7px;
  }

  &__quote-link {
    color: var(--color-brand);
    font-weight: 850;
    text-decoration: none;
  }

  &__quote-link:hover {
    text-decoration: underline;
    text-underline-offset: 3px;
  }
}

@media (width <= 520px) {
  .details-card {
    border-radius: 18px;

    &__header,
    &__item {
      padding-right: 20px;
      padding-left: 20px;
    }

    &__footer {
      padding-right: 20px;
      padding-left: 20px;
    }
  }
}
</style>
