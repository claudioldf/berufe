<script setup lang="ts">
import type { ProfessionalCustomer } from "~/types";
import { formatDateTime } from "~/utils/formatters";

defineProps<{
  customers: ProfessionalCustomer[];
  filtered?: boolean;
  loading?: boolean;
}>();
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="customer-list"
    :class="{ 'customer-list--loading': loading }"
    :aria-busy="loading ? 'true' : 'false'"
  >
    <div v-if="customers.length" class="customer-list__head" role="row">
      <span>Cliente</span>
      <span>Contato</span>
      <span>Orçamentos</span>
      <span>Último orçamento</span>
    </div>
    <NuxtLink
      v-for="customer in customers"
      :key="customer.id"
      class="customer-list__row"
      :to="`/app/professional/customers/${customer.id}`"
      :aria-label="`Abrir cliente ${customer.name}`"
    >
      <span class="customer-list__name">
        <span aria-hidden="true">{{ customer.name.charAt(0) }}</span>
        <strong>{{ customer.name }}</strong>
      </span>
      <span class="customer-list__contact">
        <strong>{{ customer.phone }}</strong>
        <small>{{ customer.email || "Sem e-mail" }}</small>
      </span>
      <span class="customer-list__quotes">
        {{ customer.quoteCount }}
        {{ customer.quoteCount === 1 ? "orçamento" : "orçamentos" }}
      </span>
      <span class="customer-list__date">
        <time v-if="customer.lastQuoteAt" :datetime="customer.lastQuoteAt">
          {{ formatDateTime(customer.lastQuoteAt) }}
        </time>
        <span v-else>Nenhum ainda</span>
        <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
      </span>
    </NuxtLink>
    <div v-if="customers.length === 0" class="customer-list__empty">
      <span><UIcon name="i-lucide-contact-round" aria-hidden="true" /></span>
      <div>
        <strong>{{
          filtered ? "Nenhum cliente encontrado" : "Nenhum cliente ainda"
        }}</strong>
        <p>
          {{
            filtered
              ? "Tente outro nome, telefone ou e-mail."
              : "Os clientes aparecem aqui quando você cria um orçamento."
          }}
        </p>
        <NuxtLink v-if="!filtered" to="/app/professional/quotes/new">
          Criar primeiro orçamento
        </NuxtLink>
      </div>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.customer-list {
  overflow: hidden;

  &__head,
  &__row {
    display: grid;
    grid-template-columns: minmax(190px, 1fr) minmax(190px, 1fr) 0.65fr 0.8fr;
    gap: 18px;
    align-items: center;
    padding: 15px 18px;
  }

  &__head {
    background: #f6f4ef;
    color: var(--ink-soft);
    font-size: 0.76rem;
    font-weight: 850;
    text-transform: uppercase;
  }

  &__row {
    border-top: 1px solid var(--line);
    color: var(--ink);
    font-size: 0.84rem;
    text-decoration: none;
    transition: opacity var(--motion-fast) ease;
  }

  &--loading &__row {
    opacity: 0.55;
  }

  &__row:hover {
    background: var(--color-surface-hover);
  }

  &__name {
    display: flex;
    align-items: center;
    gap: 10px;
    min-width: 0;
  }

  &__name > span {
    display: grid;
    flex: 0 0 auto;
    place-items: center;
    width: 34px;
    height: 34px;
    border-radius: 50%;
    background: var(--color-brand-tint);
    color: var(--color-brand);
    font-weight: 850;
    text-transform: uppercase;
  }

  &__name strong,
  &__contact strong,
  &__contact small {
    overflow: hidden;
    display: block;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__contact,
  &__date {
    min-width: 0;
  }

  &__contact small,
  &__date {
    color: var(--ink-soft);
  }

  &__quotes {
    font-weight: 750;
  }

  &__date {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
  }

  &__empty {
    display: flex;
    gap: 14px;
    align-items: start;
    padding: 28px;
  }

  &__empty > span {
    display: grid;
    place-items: center;
    width: 42px;
    height: 42px;
    border-radius: 12px;
    background: var(--color-brand-tint);
    color: var(--color-brand);
    font-size: 1.25rem;
  }

  &__empty p {
    margin: 5px 0 12px;
    color: var(--ink-soft);
  }

  &__empty a {
    color: var(--color-brand);
    font-size: 0.84rem;
    font-weight: 850;
  }
}

@media (width <= 880px) {
  .customer-list {
    &__head {
      display: none;
    }

    &__row {
      grid-template-columns: minmax(0, 1fr) auto;
    }

    &__contact {
      grid-column: 1;
      padding-left: 44px;
    }

    &__quotes {
      grid-row: 1;
      grid-column: 2;
    }

    &__date {
      grid-column: 2;
    }
  }
}

@media (width <= 560px) {
  .customer-list {
    &__row {
      grid-template-columns: 1fr;
    }

    &__contact,
    &__date,
    &__quotes {
      grid-row: auto;
      grid-column: 1;
      padding-left: 44px;
    }

    &__date {
      justify-content: start;
    }
  }
}
</style>
