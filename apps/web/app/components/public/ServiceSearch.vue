<script setup lang="ts">
import type { Neighborhood, Service } from "~/types";

withDefaults(
  defineProps<{
    services: Service[];
    neighborhoods: Neighborhood[];
    compact?: boolean;
  }>(),
  {
    compact: false,
  },
);

const emit = defineEmits<{
  submit: [payload: { service: string; neighborhood: string }];
}>();

const service = defineModel<string>("service", { default: "" });
const neighborhood = defineModel<string>("neighborhood", { default: "all" });

function submit() {
  const normalizedService = service.value.trim();
  if (!normalizedService) return;
  emit("submit", {
    service: normalizedService,
    neighborhood: neighborhood.value,
  });
}
</script>

<template>
  <form
    class="service-search"
    :class="{ 'service-search--compact': compact }"
    @submit.prevent="submit"
  >
    <div class="service-search__field service-search__field--service">
      <UIcon name="i-lucide-search" />
      <label>
        <span>O que você precisa?</span>
        <UInputMenu
          v-model="service"
          class="service-search__input"
          mode="autocomplete"
          :items="services"
          value-key="name"
          label-key="name"
          :filter-fields="['name', 'aliases']"
          open-on-focus
          name="service"
          type="search"
          autocomplete="off"
          placeholder="Ex.: eletricista, pintura…"
          :ui="{
            base: 'p-0 border-0 ring-0 shadow-none bg-transparent focus-visible:outline-none focus-visible:ring-0',
            content: 'min-w-[min(460px,calc(100vw-56px))]',
          }"
        >
          <template #item="{ item }">
            <span class="service-search__suggestion-icon">
              <UIcon :name="item.icon" aria-hidden="true" />
            </span>
            <span class="service-search__suggestion-text">
              <strong>{{ item.name }}</strong>
              <small>{{ item.description }}</small>
            </span>
            <UIcon
              name="i-lucide-arrow-up-right"
              class="service-search__suggestion-arrow"
              aria-hidden="true"
            />
          </template>
        </UInputMenu>
      </label>
    </div>

    <div class="service-search__divider" />

    <div class="service-search__field service-search__field--location">
      <UIcon name="i-lucide-map-pin" />
      <label>
        <span>Onde?</span>
        <UInputMenu
          v-model="neighborhood"
          class="service-search__input"
          :items="neighborhoods"
          value-key="code"
          label-key="name"
          :filter-fields="['name']"
          open-on-focus
          name="neighborhood"
          type="search"
          autocomplete="off"
          placeholder="Ex.: Centro, América…"
          :ui="{
            base: 'p-0 border-0 ring-0 shadow-none bg-transparent focus-visible:outline-none focus-visible:ring-0',
            content: 'min-w-[min(360px,calc(100vw-56px))]',
          }"
        >
          <template #item="{ item }">
            <span class="service-search__suggestion-icon">
              <UIcon name="i-lucide-map-pin" aria-hidden="true" />
            </span>
            <span class="service-search__suggestion-text">
              <strong>{{ item.name }}</strong>
              <small>{{ item.city }} · {{ item.stateCode }}</small>
            </span>
            <UIcon
              name="i-lucide-arrow-up-right"
              class="service-search__suggestion-arrow"
              aria-hidden="true"
            />
          </template>
        </UInputMenu>
      </label>
    </div>

    <UButton type="submit" color="primary" class="service-search__button">
      <span>Encontrar</span>
      <UIcon name="i-lucide-arrow-right" />
    </UButton>
  </form>
</template>

<style scoped lang="scss">
.service-search {
  position: relative;
  z-index: 10;
  display: grid;
  grid-template-columns: minmax(250px, 1.35fr) 1px minmax(190px, 0.8fr) auto;
  align-items: center;
  width: 100%;
  padding: 9px;
  border: 1px solid rgb(23 53 47 / 14%);
  border-radius: 18px;
  background: white;
  box-shadow: 0 20px 55px rgb(23 53 47 / 13%);
  &__field {
    position: relative;
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    gap: 6px;
    min-width: 0;
    padding: 4px 11px;
  }
  &__field > svg {
    color: var(--color-brand);
    font-size: 1.15rem;
  }
  &__field label {
    display: grid;
    min-width: 0;
  }
  &__field label > span {
    color: var(--ink-soft);
    font-size: 0.84rem;
    font-weight: 800;
    letter-spacing: 0;
    text-transform: uppercase;
  }
  &__input {
    width: 100%;
    min-width: 0;
    padding: 4px 0 0;
    border: 0;
    background: transparent;
    color: var(--ink);
    font-size: 0.9rem;
    font-weight: 750;
  }
  &__divider {
    width: 1px;
    height: 38px;
    background: var(--line);
  }
  &__button {
    align-self: stretch;
    min-height: 52px;
    justify-content: center;
    padding-inline: 24px;
    border-radius: 13px;
    font-weight: 800;
  }
  &__suggestion-icon {
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    border-radius: 10px;
    background: var(--mint);
    color: var(--color-brand);
  }
  &__suggestion-text {
    min-width: 0;
  }
  &__suggestion-text strong,
  &__suggestion-text small {
    display: block;
  }
  &__suggestion-text strong {
    font-size: 0.84rem;
  }
  &__suggestion-text small {
    overflow: hidden;
    margin-top: 2px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  &__suggestion-arrow {
    flex-shrink: 0;
    align-self: center;
    margin-left: auto;
    color: #789089;
  }
  &--compact {
    box-shadow: var(--shadow-sm);
  }

  &__field {
    :deep(input[type="search"]::-webkit-search-cancel-button) {
      appearance: none;
    }

    :deep(button) {
      top: calc(-50% - 20px / 2);
    }
  }
}

@media (width <= 760px) {
  .service-search {
    grid-template-columns: 1fr;
    gap: 0;
    padding: 8px;
    &__divider {
      display: none;
    }
    &__field {
      padding: 10px 12px;
    }
    &__field--location {
      border-top: 1px solid var(--line);
    }
    &__button {
      min-height: 48px;
      margin-top: 5px;
    }
  }
}
</style>
