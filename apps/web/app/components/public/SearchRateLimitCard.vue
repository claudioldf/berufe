<script setup lang="ts">
import type {
  Service,
  StructuredSearchCity,
  StructuredSearchPayload,
} from "~/types";

withDefaults(
  defineProps<{
    services: Service[];
    cities: StructuredSearchCity[];
    loading?: boolean;
  }>(),
  { loading: false },
);

defineEmits<{
  search: [payload: StructuredSearchPayload];
}>();
</script>

<template>
  <DesignSystemSurfaceCard as="article" class="search-pause">
    <div class="search-pause__visual" aria-hidden="true">
      <span class="search-pause__icon">
        <UIcon name="i-lucide-clock-3" />
      </span>
      <span class="search-pause__badge">
        <span></span>
        <span></span>
      </span>
    </div>

    <div class="search-pause__body" role="status" aria-live="polite">
      <span class="search-pause__eyebrow">Uma pausa rapidinha</span>
      <h2 class="search-pause__title">
        A busca por descrição volta em alguns minutos
      </h2>
      <p class="search-pause__message">
        Você fez várias buscas seguidas. Para continuar agora, escolha o serviço
        e a cidade abaixo.
      </p>

      <div class="search-pause__footer">
        <div class="search-pause__fallback">
          <PublicStructuredSearchFallback
            :services="services"
            :cities="cities"
            :loading="loading"
            @submit="$emit('search', $event)"
          />
        </div>
      </div>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.search-pause {
  position: relative;
  display: grid;
  grid-template-columns: 104px minmax(0, 1fr);
  align-items: center;
  gap: clamp(22px, 4vw, 36px);
  min-height: 280px;
  padding: clamp(30px, 5vw, 48px);
  overflow: hidden;
  border-color: rgb(84 137 126 / 22%);
  background:
    radial-gradient(circle at 100% 0%, rgb(249 220 192 / 48%), transparent 36%),
    linear-gradient(145deg, rgb(255 255 255 / 96%), rgb(239 249 246 / 94%));
}

.search-pause::after {
  position: absolute;
  right: -54px;
  bottom: -76px;
  width: 190px;
  height: 190px;
  border: 1px solid rgb(199 119 103 / 13%);
  border-radius: 50%;
  content: "";
}

.search-pause__visual {
  position: relative;
  z-index: 1;
  display: grid;
  place-items: center;
  width: 104px;
  height: 104px;
  border: 1px solid rgb(199 119 103 / 16%);
  border-radius: 30px;
  background: linear-gradient(145deg, #fff7ed, #f7dfc8);
  box-shadow: 0 18px 40px rgb(86 68 50 / 11%);
  transform: rotate(3deg);
}

.search-pause__icon {
  color: #9f664e;
  font-size: 2.6rem;
  transform: rotate(-3deg);
}

.search-pause__badge {
  position: absolute;
  right: -9px;
  top: -9px;
  display: grid;
  grid-auto-flow: column;
  place-items: center;
  gap: 3px;
  width: 34px;
  height: 34px;
  border: 4px solid white;
  border-radius: 50%;
  background: var(--color-brand);
}

.search-pause__badge > span {
  width: 3px;
  height: 10px;
  border-radius: 999px;
  background: white;
}

.search-pause__body {
  position: relative;
  z-index: 1;
  min-width: 0;
}

.search-pause__eyebrow {
  color: var(--color-brand);
  font-size: 0.74rem;
  font-weight: 900;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.search-pause__title {
  margin: 7px 0 8px;
  font-family: var(--font-display);
  font-size: clamp(1.65rem, 3vw, 2.2rem);
  font-weight: 600;
  letter-spacing: -0.025em;
  line-height: 1.1;
}

.search-pause__message {
  max-width: 610px;
  margin: 0;
  color: var(--ink-soft);
  line-height: 1.65;
}

.search-pause__footer {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid rgb(23 53 47 / 9%);
}

.search-pause__time {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 9px 13px;
  border-radius: 999px;
  background: rgb(84 137 126 / 11%);
  color: var(--color-brand);
  font-size: 0.84rem;
  font-weight: 800;
  white-space: nowrap;
}

.search-pause__fallback {
  width: 100%;
  position: relative;
  z-index: 2;
  display: grid;
  grid-column: 1 / -1;
  gap: 14px;
}

@media (width <= 640px) {
  .search-pause {
    grid-template-columns: 1fr;
    justify-items: start;
    min-height: 0;
  }

  .search-pause__visual {
    width: 78px;
    height: 78px;
    border-radius: 23px;
  }

  .search-pause__icon {
    font-size: 2rem;
  }

  .search-pause__footer {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
