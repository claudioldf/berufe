<script setup lang="ts">
withDefaults(
  defineProps<{
    message: string;
    canRetry?: boolean;
  }>(),
  { canRetry: true },
);

defineEmits<{
  retry: [];
}>();
</script>

<template>
  <DesignSystemSurfaceCard as="article" class="search-failure" role="alert">
    <div class="search-failure__visual" aria-hidden="true">
      <span class="search-failure__icon">
        <UIcon name="i-lucide-search-x" />
      </span>
      <span class="search-failure__sparkle">
        <UIcon name="i-lucide-sparkles" />
      </span>
    </div>

    <div class="search-failure__body">
      <span class="search-failure__eyebrow">Ops, tivemos um imprevisto</span>
      <h2 class="search-failure__title">Não foi possível concluir a busca.</h2>
      <p class="search-failure__message">{{ message }}</p>

      <div v-if="canRetry" class="search-failure__actions">
        <UButton
          type="button"
          color="primary"
          variant="soft"
          icon="i-lucide-refresh-cw"
          @click="$emit('retry')"
        >
          Tentar novamente
        </UButton>
      </div>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.search-failure {
  position: relative;
  display: grid;
  grid-template-columns: 104px minmax(0, 1fr);
  align-items: center;
  gap: clamp(22px, 4vw, 36px);
  min-height: 280px;
  padding: clamp(30px, 5vw, 48px);
  overflow: hidden;
  border-color: rgb(164 75 63 / 24%);
  background:
    radial-gradient(circle at 100% 0%, rgb(223 241 235 / 78%), transparent 38%),
    linear-gradient(145deg, rgb(255 255 255 / 96%), rgb(255 248 244 / 94%));
}

.search-failure::after {
  position: absolute;
  right: -56px;
  bottom: -74px;
  width: 190px;
  height: 190px;
  border: 1px solid rgb(84 137 126 / 12%);
  border-radius: 50%;
  content: "";
}

.search-failure__visual {
  position: relative;
  z-index: 1;
  display: grid;
  place-items: center;
  width: 104px;
  height: 104px;
  border: 1px solid rgb(84 137 126 / 14%);
  border-radius: 30px;
  background: linear-gradient(145deg, #edf8f4, #d9eee7);
  box-shadow: 0 18px 40px rgb(44 83 75 / 12%);
  transform: rotate(-3deg);
}

.search-failure__icon {
  color: var(--color-brand);
  font-size: 2.6rem;
  transform: rotate(3deg);
}

.search-failure__sparkle {
  position: absolute;
  right: -9px;
  top: -9px;
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border: 4px solid white;
  border-radius: 50%;
  background: #c77767;
  color: white;
  font-size: 0.9rem;
}

.search-failure__body {
  position: relative;
  z-index: 1;
  min-width: 0;
}

.search-failure__eyebrow {
  color: #a44b3f;
  font-size: 0.74rem;
  font-weight: 900;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.search-failure__title {
  margin: 7px 0 8px;
  font-family: var(--font-display);
  font-size: clamp(1.65rem, 3vw, 2.2rem);
  font-weight: 600;
  letter-spacing: -0.025em;
  line-height: 1.1;
}

.search-failure__message {
  max-width: 580px;
  margin: 0;
  color: var(--ink-soft);
  line-height: 1.65;
}

.search-failure__actions {
  margin-top: 22px;
}

@media (width <= 640px) {
  .search-failure {
    grid-template-columns: 1fr;
    justify-items: start;
    min-height: 0;
  }

  .search-failure__visual {
    width: 78px;
    height: 78px;
    border-radius: 23px;
  }

  .search-failure__icon {
    font-size: 2rem;
  }
}
</style>
