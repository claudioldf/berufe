<script setup lang="ts">
import { onMounted, shallowRef, watch } from "vue";
import { useLocations } from "~/composables/useLocations";
import { useBrazilianMobilePhoneMask } from "~/composables/useBrazilianMobilePhoneMask";
import { sanitizeBrazilianMobilePhone } from "~/utils/brazilian-phone";
import type {
  AdminProfessionalSort,
  AdminProfessionalsSummary,
  AdminProfessionalTriState,
} from "~/types";

const props = defineProps<{
  summary: AdminProfessionalsSummary;
  q: string;
  phone: string;
  city: string | null;
  state: string | null;
  identityVerified: AdminProfessionalTriState;
  onboardingFinished: AdminProfessionalTriState;
  sort: AdminProfessionalSort;
  isLoading: boolean;
}>();

const emit = defineEmits<{
  search: [value: string];
  phone: [value: string];
  city: [value: string | null];
  state: [value: string | null];
  identityVerified: [value: AdminProfessionalTriState];
  onboardingFinished: [value: AdminProfessionalTriState];
  sort: [value: AdminProfessionalSort];
  clear: [];
}>();

const { states, cities, loadStates, loadCities } = useLocations();

const nameInput = shallowRef(props.q);
const phoneInput = shallowRef(props.phone);
const maskedPhoneInput = useBrazilianMobilePhoneMask(phoneInput);

watch(
  () => props.q,
  (value) => {
    nameInput.value = value;
  },
);
watch(
  () => props.phone,
  (value) => {
    phoneInput.value = value;
  },
);

onMounted(async () => {
  await loadStates();
  if (props.state) await loadCities(props.state);
});

function changeState(event: Event) {
  const value = (event.target as HTMLSelectElement).value;
  emit("state", value || null);
  if (value) void loadCities(value);
}

function changeCity(event: Event) {
  emit("city", (event.target as HTMLSelectElement).value || null);
}

function changeIdentity(event: Event) {
  emit(
    "identityVerified",
    (event.target as HTMLSelectElement).value as AdminProfessionalTriState,
  );
}

function changeOnboarding(event: Event) {
  emit(
    "onboardingFinished",
    (event.target as HTMLSelectElement).value as AdminProfessionalTriState,
  );
}

function changeSort(event: Event) {
  emit(
    "sort",
    (event.target as HTMLSelectElement).value as AdminProfessionalSort,
  );
}

function submit() {
  emit("search", nameInput.value.trim());
  emit("phone", sanitizeBrazilianMobilePhone(phoneInput.value));
}
</script>

<template>
  <section
    class="professionals-overview"
    aria-labelledby="professionals-overview-title"
  >
    <div class="professionals-overview__heading">
      <div>
        <h2 id="professionals-overview-title">Profissionais cadastrados</h2>
        <p>Visualize, filtre e gerencie a publicação de qualquer perfil.</p>
      </div>
      <span
        v-if="isLoading"
        class="professionals-overview__loading"
        role="status"
      >
        <UIcon name="i-lucide-loader-circle" aria-hidden="true" />
        Atualizando…
      </span>
    </div>

    <div
      class="professionals-overview__cards"
      aria-label="Resumo dos profissionais"
    >
      <div class="professionals-overview__card">
        <span>Total</span>
        <strong>{{ props.summary.total }}</strong>
      </div>
      <div class="professionals-overview__card">
        <span>Publicados</span>
        <strong>{{ props.summary.published }}</strong>
      </div>
      <div class="professionals-overview__card">
        <span>Suspensos</span>
        <strong>{{ props.summary.suspended }}</strong>
      </div>
      <div class="professionals-overview__card">
        <span>Onboarding concluído</span>
        <strong>{{ props.summary.onboardingFinished }}</strong>
      </div>
      <div class="professionals-overview__card">
        <span>Identidade verificada</span>
        <strong>{{ props.summary.identityVerified }}</strong>
      </div>
    </div>

    <form
      class="professionals-overview__search"
      role="search"
      @submit.prevent="submit"
    >
      <label for="professionals-q">
        <span>Nome</span>
        <input
          id="professionals-q"
          v-model="nameInput"
          name="q"
          type="search"
          autocomplete="off"
          maxlength="100"
          placeholder="Nome do profissional…"
        />
      </label>
      <label for="professionals-phone">
        <span>Telefone</span>
        <input
          id="professionals-phone"
          v-model="maskedPhoneInput"
          name="phone"
          type="tel"
          inputmode="tel"
          autocomplete="off"
          maxlength="16"
          placeholder="(47) 9 9999-9999"
        />
      </label>
      <UButton type="submit" color="primary" label="Pesquisar" />
    </form>

    <div class="professionals-overview__filters">
      <label for="professionals-state">
        <span>Estado</span>
        <select
          id="professionals-state"
          :value="props.state ?? ''"
          @change="changeState"
        >
          <option value="">Todos</option>
          <option
            v-for="item in states"
            :key="item.code"
            :value="item.abbreviation"
          >
            {{ item.name }} ({{ item.abbreviation }})
          </option>
        </select>
      </label>

      <label for="professionals-city">
        <span>Cidade</span>
        <DesignSystemDisabledTooltip
          :reason="!props.state ? 'Selecione um estado primeiro' : null"
        >
          <select
            id="professionals-city"
            :value="props.city ?? ''"
            :disabled="!props.state"
            @change="changeCity"
          >
            <option value="">Todas</option>
            <option v-for="item in cities" :key="item.code" :value="item.code">
              {{ item.name }}
            </option>
          </select>
        </DesignSystemDisabledTooltip>
      </label>

      <label for="professionals-identity">
        <span>Identidade verificada</span>
        <select
          id="professionals-identity"
          :value="props.identityVerified"
          @change="changeIdentity"
        >
          <option value="all">Todos</option>
          <option value="yes">Sim</option>
          <option value="no">Não</option>
        </select>
      </label>

      <label for="professionals-onboarding">
        <span>Concluiu onboarding</span>
        <select
          id="professionals-onboarding"
          :value="props.onboardingFinished"
          @change="changeOnboarding"
        >
          <option value="all">Todos</option>
          <option value="yes">Sim</option>
          <option value="no">Não</option>
        </select>
      </label>

      <label for="professionals-sort">
        <span>Ordenar por</span>
        <select
          id="professionals-sort"
          :value="props.sort"
          @change="changeSort"
        >
          <option value="recent">Cadastro recente</option>
          <option value="last_login_desc">Último acesso</option>
          <option value="name_asc">Nome (A–Z)</option>
        </select>
      </label>

      <UButton
        type="button"
        color="neutral"
        variant="ghost"
        label="Limpar filtros"
        @click="emit('clear')"
      />
    </div>
  </section>
</template>

<style scoped lang="scss">
.professionals-overview {
  display: grid;
  gap: 16px;
  padding: 18px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  background: rgb(255 255 255 / 76%);

  &__heading {
    display: flex;
    align-items: start;
    justify-content: space-between;
    gap: 18px;
  }

  h2,
  p {
    margin: 0;
  }

  h2 {
    color: var(--color-brand-strong);
    font-size: 1rem;
    font-weight: 850;
  }

  p {
    margin-top: 3px;
    color: var(--color-text-muted);
    font-size: 0.78rem;
  }

  &__loading {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: var(--color-text-muted);
    font-size: 0.76rem;
    font-weight: 750;
  }

  &__cards {
    display: grid;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    gap: 8px;
  }

  &__card {
    display: grid;
    gap: 7px;
    min-width: 0;
    padding: 11px 12px;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-md);
    background: var(--color-surface);

    span {
      min-height: 2em;
      color: var(--color-text-muted);
      font-size: 0.72rem;
      font-weight: 750;
      line-height: 1.1;
    }

    strong {
      color: var(--color-brand-strong);
      font-size: 1.25rem;
      font-variant-numeric: tabular-nums;
      line-height: 1;
    }
  }

  &__search,
  &__filters {
    display: grid;
    align-items: end;
    gap: 10px;

    label {
      display: grid;
      gap: 5px;
      min-width: 0;
      color: var(--color-text-muted);
      font-size: 0.7rem;
      font-weight: 800;
    }

    input,
    select {
      width: 100%;
      min-height: 38px;
      padding: 8px 10px;
      border: 1px solid var(--color-border);
      border-radius: var(--radius-md);
      background-color: var(--color-surface-control);
      color: var(--color-text);
      font-size: 0.8rem;
    }
  }

  &__search {
    grid-template-columns: minmax(200px, 1fr) minmax(160px, 0.6fr) auto;
  }

  &__filters {
    grid-template-columns: repeat(4, minmax(140px, 1fr)) auto;
  }
}

@media (width <= 1100px) {
  .professionals-overview {
    &__cards {
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }

    &__search,
    &__filters {
      grid-template-columns: 1fr 1fr;
    }
  }
}

@media (width <= 600px) {
  .professionals-overview {
    padding: 14px;

    &__heading {
      display: grid;
    }

    &__cards {
      grid-template-columns: 1fr 1fr;
    }
  }
}
</style>
