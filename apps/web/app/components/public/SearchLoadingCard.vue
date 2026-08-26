<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    structured?: boolean;
  }>(),
  { structured: false },
);
</script>

<template>
  <DesignSystemSurfaceCard
    as="article"
    class="search-loading"
    role="status"
    aria-live="polite"
    aria-atomic="true"
    aria-busy="true"
  >
    <div class="search-loading__visual" aria-hidden="true">
      <span class="search-loading__orbit search-loading__orbit--outer" />
      <span class="search-loading__orbit search-loading__orbit--inner" />
      <span class="search-loading__icon">
        <UIcon name="i-lucide-search" />
      </span>
      <span class="search-loading__badge">
        <UIcon name="i-lucide-user-search" />
      </span>
    </div>

    <div class="search-loading__body">
      <span class="search-loading__eyebrow">Buscando na rede Berufe</span>
      <h2 class="search-loading__title">
        {{
          props.structured
            ? "Buscando profissionais com os filtros selecionados..."
            : "Entendendo seu pedido e buscando profissionais..."
        }}
      </h2>
      <p class="search-loading__message">
        {{
          props.structured
            ? "Estamos combinando o serviço e a cidade escolhidos com os profissionais disponíveis."
            : "Estamos identificando o serviço, a região e os sinais de confiança para organizar os resultados."
        }}
      </p>

      <div class="search-loading__progress" aria-hidden="true">
        <span class="search-loading__progress-bar" />
      </div>

      <div class="search-loading__signals" aria-hidden="true">
        <span class="search-loading__signal">
          <UIcon name="i-lucide-wrench" />
          Serviço
        </span>
        <span class="search-loading__signal">
          <UIcon name="i-lucide-map-pin" />
          Região
        </span>
        <span class="search-loading__signal">
          <UIcon name="i-lucide-badge-check" />
          Confiança
        </span>
      </div>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.search-loading {
  position: relative;
  display: grid;
  grid-template-columns: 116px minmax(0, 1fr);
  align-items: center;
  gap: clamp(24px, 4vw, 42px);
  min-height: 280px;
  padding: clamp(30px, 5vw, 50px);
  overflow: hidden;
  border-color: rgb(84 137 126 / 24%);
  background:
    radial-gradient(circle at 100% 0%, rgb(248 117 93 / 13%), transparent 34%),
    radial-gradient(circle at 0% 100%, rgb(182 223 207 / 42%), transparent 40%),
    linear-gradient(145deg, rgb(255 255 255 / 97%), rgb(239 249 246 / 95%));

  &::after {
    position: absolute;
    right: -64px;
    bottom: -88px;
    width: 220px;
    height: 220px;
    border: 1px solid rgb(84 137 126 / 13%);
    border-radius: 50%;
    content: "";
  }

  &__visual {
    position: relative;
    z-index: 1;
    display: grid;
    place-items: center;
    width: 116px;
    height: 116px;
  }

  &__orbit {
    position: absolute;
    border-radius: 50%;

    &--outer {
      inset: 0;
      border: 1px dashed rgb(18 98 93 / 32%);
      animation: search-loading-orbit 8s linear infinite;
    }

    &--inner {
      inset: 13px;
      border: 1px solid rgb(18 98 93 / 15%);
      animation: search-loading-orbit-reverse 5s linear infinite;
    }

    &--outer::before,
    &--inner::before {
      position: absolute;
      border-radius: 50%;
      content: "";
    }

    &--outer::before {
      top: 8px;
      left: 13px;
      width: 10px;
      height: 10px;
      background: var(--coral);
      box-shadow: 0 0 0 6px rgb(248 117 93 / 12%);
    }

    &--inner::before {
      right: 3px;
      bottom: 16px;
      width: 8px;
      height: 8px;
      background: var(--color-brand);
      box-shadow: 0 0 0 5px rgb(18 98 93 / 10%);
    }
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 66px;
    height: 66px;
    border: 1px solid rgb(84 137 126 / 18%);
    border-radius: 22px;
    background: linear-gradient(145deg, #f7fffc, #d8f0e7);
    color: var(--color-brand);
    font-size: 2rem;
    box-shadow: 0 18px 40px rgb(44 83 75 / 14%);
    animation: search-loading-float 2.4s ease-in-out infinite;
  }

  &__badge {
    position: absolute;
    top: 7px;
    right: 5px;
    display: grid;
    place-items: center;
    width: 32px;
    height: 32px;
    border: 4px solid white;
    border-radius: 50%;
    background: var(--coral);
    color: white;
    font-size: 0.82rem;
    box-shadow: 0 8px 18px rgb(156 75 61 / 18%);
    animation: search-loading-badge 1.8s ease-in-out infinite;
  }

  &__body {
    position: relative;
    z-index: 1;
    min-width: 0;
  }

  &__eyebrow {
    color: var(--color-brand);
    font-size: 0.74rem;
    font-weight: 900;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }

  &__title {
    max-width: 650px;
    margin: 7px 0 9px;
    font-family: var(--font-display);
    font-size: clamp(1.65rem, 3vw, 2.25rem);
    font-weight: 600;
    letter-spacing: -0.025em;
    line-height: 1.1;
  }

  &__message {
    max-width: 620px;
    margin: 0;
    color: var(--ink-soft);
    line-height: 1.65;
  }

  &__progress {
    width: min(100%, 560px);
    height: 6px;
    margin-top: 24px;
    overflow: hidden;
    border-radius: var(--radius-pill);
    background: rgb(18 98 93 / 10%);
  }

  &__progress-bar {
    display: block;
    width: 42%;
    height: 100%;
    border-radius: inherit;
    background: linear-gradient(
      90deg,
      var(--color-brand-muted),
      var(--color-brand)
    );
    box-shadow: 0 0 12px rgb(18 98 93 / 22%);
    animation: search-loading-progress 1.8s ease-in-out infinite;
  }

  &__signals {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 15px;
  }

  &__signal {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 7px 10px;
    border: 1px solid rgb(18 98 93 / 11%);
    border-radius: var(--radius-pill);
    background: rgb(255 255 255 / 66%);
    color: var(--ink-soft);
    font-size: 0.77rem;
    font-weight: 800;
  }

  &__signal > svg {
    color: var(--color-brand);
    font-size: 0.92rem;
  }
}

@keyframes search-loading-orbit {
  to {
    transform: rotate(360deg);
  }
}

@keyframes search-loading-orbit-reverse {
  to {
    transform: rotate(-360deg);
  }
}

@keyframes search-loading-float {
  0%,
  100% {
    transform: translateY(0) rotate(-2deg);
  }

  50% {
    transform: translateY(-5px) rotate(2deg);
  }
}

@keyframes search-loading-badge {
  0%,
  100% {
    transform: scale(0.92) rotate(-5deg);
  }

  50% {
    transform: scale(1.08) rotate(5deg);
  }
}

@keyframes search-loading-progress {
  0% {
    transform: translateX(-105%);
  }

  55% {
    transform: translateX(85%);
  }

  100% {
    transform: translateX(245%);
  }
}

@media (width <= 640px) {
  .search-loading {
    grid-template-columns: 1fr;
    justify-items: start;
    min-height: 0;

    &__visual {
      width: 88px;
      height: 88px;
    }

    &__icon {
      width: 52px;
      height: 52px;
      border-radius: 18px;
      font-size: 1.55rem;
    }

    &__badge {
      top: 1px;
      right: 0;
      width: 28px;
      height: 28px;
      border-width: 3px;
    }
  }
}

@media (prefers-reduced-motion: reduce) {
  .search-loading {
    &__orbit,
    &__icon,
    &__badge,
    &__progress-bar {
      animation: none;
    }

    &__progress-bar {
      width: 100%;
      opacity: 0.68;
      transform: none;
    }
  }
}
</style>
