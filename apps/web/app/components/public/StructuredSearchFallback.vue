<script setup lang="ts">
import { computed, shallowRef, watch } from "vue";
import type {
  Service,
  StructuredSearchCity,
  StructuredSearchPayload,
} from "~/types";

const props = withDefaults(
  defineProps<{
    services: Service[];
    cities: StructuredSearchCity[];
    loading?: boolean;
  }>(),
  { loading: false },
);

const emit = defineEmits<{
  submit: [payload: StructuredSearchPayload];
}>();

const serviceId = shallowRef("");
const cityId = shallowRef("");
const selectedService = computed(() =>
  props.services.find((service) => service.id === serviceId.value),
);
const selectedCity = computed(() =>
  props.cities.find((city) => city.id === cityId.value),
);
const canSubmit = computed(
  () => Boolean(selectedService.value && selectedCity.value) && !props.loading,
);

watch(
  () => props.cities,
  (cities) => {
    if (!cities.some((city) => city.id === cityId.value)) {
      cityId.value = cities[0]?.id ?? "";
    }
  },
  { immediate: true },
);

function submit() {
  const service = selectedService.value;
  const city = selectedCity.value;
  if (!canSubmit.value || !service || !city) return;

  emit("submit", {
    serviceId: service.id,
    serviceName: service.name,
    stateCode: city.stateCode,
    city: city.name,
  });
}
</script>

<template>
  <form class="structured-search" @submit.prevent="submit">
    <div class="structured-search__field">
      <UIcon name="i-lucide-wrench" aria-hidden="true" />
      <label>
        <span>Serviço</span>
        <UInputMenu
          v-model="serviceId"
          class="structured-search__input"
          :items="services"
          value-key="id"
          label-key="name"
          :filter-fields="['name', 'aliases']"
          open-on-focus
          name="fallback_service"
          autocomplete="off"
          placeholder="Selecione um serviço"
          :ui="{
            base: 'p-0 border-0 ring-0 shadow-none bg-transparent focus-visible:outline-none focus-visible:ring-0',
            content: 'min-w-[min(420px,calc(100vw-64px))]',
          }"
        >
          <template #item="{ item }">
            <span class="structured-search__suggestion-icon">
              <UIcon :name="item.icon" aria-hidden="true" />
            </span>
            <span class="structured-search__suggestion-copy">
              <strong>{{ item.name }}</strong>
              <small>{{ item.description }}</small>
            </span>
          </template>
        </UInputMenu>
      </label>
    </div>

    <span class="structured-search__divider" aria-hidden="true"></span>

    <div class="structured-search__field">
      <UIcon name="i-lucide-map-pin" aria-hidden="true" />
      <label>
        <span>Cidade</span>
        <UInputMenu
          v-model="cityId"
          class="structured-search__input"
          :items="cities"
          value-key="id"
          label-key="name"
          open-on-focus
          name="fallback_city"
          autocomplete="off"
          placeholder="Selecione uma cidade"
          :ui="{
            base: 'p-0 border-0 ring-0 shadow-none bg-transparent focus-visible:outline-none focus-visible:ring-0',
          }"
        >
          <template #item="{ item }">
            <span class="structured-search__suggestion-icon">
              <UIcon name="i-lucide-map-pin" aria-hidden="true" />
            </span>
            <span class="structured-search__suggestion-copy">
              <strong>{{ item.name }}</strong>
              <small>{{ item.stateCode }}</small>
            </span>
          </template>
        </UInputMenu>
      </label>
    </div>

    <UButton
      type="submit"
      color="primary"
      class="structured-search__button"
      :disabled="!canSubmit"
      :loading="loading"
    >
      <span>Buscar novamente</span>
      <UIcon name="i-lucide-arrow-right" aria-hidden="true" />
    </UButton>
  </form>
</template>

<style scoped lang="scss">
.structured-search {
  display: grid;
  grid-template-columns: minmax(230px, 1.25fr) 1px minmax(170px, 0.75fr) auto;
  align-items: stretch;
  width: 100%;
  padding: 8px;
  border: 1px solid rgb(23 53 47 / 13%);
  border-radius: 17px;
  background: rgb(255 255 255 / 88%);
  box-shadow: 0 14px 34px rgb(23 53 47 / 8%);
}

.structured-search__field {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  align-items: center;
  gap: 8px;
  min-width: 0;
  padding: 6px 13px;
}

.structured-search__field > svg {
  color: var(--color-brand);
  font-size: 1.1rem;
}

.structured-search__field label {
  display: grid;
  min-width: 0;
}

.structured-search__field label > span {
  color: var(--ink-soft);
  font-size: 0.7rem;
  font-weight: 900;
  letter-spacing: 0.07em;
  text-transform: uppercase;
}

.structured-search__input {
  min-width: 0;
  padding-top: 2px;
  color: var(--ink);
  font-size: 0.9rem;
  font-weight: 750;
}

.structured-search__divider {
  align-self: center;
  width: 1px;
  height: 38px;
  background: var(--line);
}

.structured-search__button {
  min-height: 54px;
  justify-content: center;
  padding-inline: 20px;
  border-radius: 12px;
  font-weight: 850;
}

.structured-search__suggestion-icon {
  display: grid;
  flex: 0 0 auto;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: var(--mint);
  color: var(--color-brand);
}

.structured-search__suggestion-copy {
  min-width: 0;
}

.structured-search__suggestion-copy strong,
.structured-search__suggestion-copy small {
  display: block;
}

.structured-search__suggestion-copy small {
  overflow: hidden;
  color: var(--ink-soft);
  font-size: 0.78rem;
  text-overflow: ellipsis;
  white-space: nowrap;
}

@media (width <= 820px) {
  .structured-search {
    grid-template-columns: 1fr;
  }

  .structured-search__divider {
    width: 100%;
    height: 1px;
  }

  .structured-search__field {
    padding: 10px 12px;
  }

  .structured-search__button {
    margin-top: 5px;
  }
}
</style>
