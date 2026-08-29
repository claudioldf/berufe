<script setup lang="ts">
import { computed } from "vue";

interface Props {
  serviceName: string;
  serviceSlug: string;
  serviceIcon: string;
}

const props = defineProps<Props>();

const serviceLabel = computed(() =>
  props.serviceName.toLocaleLowerCase("pt-BR"),
);
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="service-hub-empty"
    aria-labelledby="service-hub-empty-title"
  >
    <div class="service-hub-empty__copy">
      <span class="service-hub-empty__eyebrow">
        <UIcon name="i-lucide-star" aria-hidden="true" />
        Nossa rede está crescendo
      </span>

      <h2 id="service-hub-empty-title" class="service-hub-empty__title">
        Ainda estamos ampliando a oferta de
        <em>{{ serviceLabel }}</em> por cidade.
      </h2>
      <p class="service-hub-empty__description">
        Já pode haver profissionais atendendo a sua região. Faça uma busca para
        conferir as opções disponíveis agora.
      </p>

      <div class="service-hub-empty__actions">
        <UButton
          to="/encontrar"
          color="primary"
          size="lg"
          icon="i-lucide-search"
          trailing-icon="i-lucide-arrow-right"
        >
          Buscar profissionais
        </UButton>
        <UButton
          :to="`/para-profissionais/${props.serviceSlug}`"
          color="neutral"
          variant="outline"
          size="lg"
          icon="i-lucide-user-plus"
        >
          Criar perfil grátis
        </UButton>
      </div>

      <span class="service-hub-empty__assurance">
        <UIcon name="i-lucide-heart-handshake" aria-hidden="true" />
        Você decide com quem falar.
      </span>
    </div>

    <div class="service-hub-empty__visual" aria-hidden="true">
      <div class="service-hub-empty__orbit">
        <span class="service-hub-empty__ring service-hub-empty__ring--inner" />
        <span class="service-hub-empty__ring service-hub-empty__ring--outer" />

        <div class="service-hub-empty__service">
          <span class="service-hub-empty__service-icon">
            <UIcon :name="props.serviceIcon" />
          </span>
          <strong>{{ props.serviceName }}</strong>
          <small>Rede em expansão</small>
        </div>

        <span
          class="service-hub-empty__marker service-hub-empty__marker--location"
        >
          <UIcon name="i-lucide-map-pin" />
        </span>
        <span
          class="service-hub-empty__marker service-hub-empty__marker--people"
        >
          <UIcon name="i-lucide-users-round" />
        </span>
        <span
          class="service-hub-empty__marker service-hub-empty__marker--spark"
        >
          <UIcon name="i-lucide-star" />
        </span>
      </div>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.service-hub-empty {
  position: relative;
  isolation: isolate;
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(280px, 0.85fr);
  align-items: center;
  gap: clamp(28px, 5vw, 68px);
  overflow: hidden;
  padding: clamp(28px, 5vw, 56px);
  background:
    radial-gradient(circle at 92% 8%, rgb(166 222 201 / 78%), transparent 34%),
    radial-gradient(circle at 4% 96%, rgb(255 231 185 / 54%), transparent 30%),
    linear-gradient(135deg, #fff 0%, var(--color-brand-tint-subtle) 100%);

  &::before {
    position: absolute;
    z-index: -1;
    inset: 0;
    opacity: 0.34;
    background-image: radial-gradient(
      circle,
      rgb(18 98 93 / 22%) 1px,
      transparent 1px
    );
    background-size: 24px 24px;
    mask-image: linear-gradient(90deg, transparent 18%, #000 100%);
    content: "";
  }

  &__copy {
    position: relative;
    z-index: 1;
  }

  &__eyebrow {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    color: var(--color-brand);
    font-size: 0.78rem;
    font-weight: 850;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  &__title {
    max-width: 650px;
    margin: 14px 0 12px;
    font-family: var(--font-display);
    font-size: clamp(1.9rem, 4vw, 3rem);
    font-weight: 500;
    letter-spacing: -0.045em;
    line-height: 1.05;
  }

  &__title em {
    color: var(--color-brand);
    font-weight: inherit;
    font-style: normal;
  }

  &__description {
    max-width: 590px;
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.96rem;
    line-height: 1.65;
  }

  &__actions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 26px;
  }

  &__assurance {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    margin-top: 20px;
    color: var(--ink-soft);
    font-size: 0.8rem;
    font-weight: 750;
  }

  &__assurance svg {
    color: var(--color-brand);
    font-size: 1rem;
  }

  &__visual {
    display: grid;
    place-items: center;
    min-height: 330px;
  }

  &__orbit {
    position: relative;
    display: grid;
    place-items: center;
    width: min(100%, 330px);
    aspect-ratio: 1;
  }

  &__ring {
    position: absolute;
    border: 1px dashed rgb(18 98 93 / 25%);
    border-radius: 50%;
  }

  &__ring--inner {
    width: 68%;
    aspect-ratio: 1;
    background: rgb(255 255 255 / 34%);
  }

  &__ring--outer {
    width: 100%;
    aspect-ratio: 1;
  }

  &__service {
    position: relative;
    z-index: 2;
    display: grid;
    justify-items: center;
    width: 168px;
    padding: 24px 18px 20px;
    border: 1px solid rgb(18 98 93 / 14%);
    border-radius: 26px;
    background: rgb(255 255 255 / 92%);
    box-shadow: 0 28px 60px rgb(23 53 47 / 18%);
    text-align: center;
    transform: rotate(-2deg);
  }

  &__service-icon {
    display: grid;
    place-items: center;
    width: 58px;
    height: 58px;
    margin-bottom: 13px;
    border-radius: 18px;
    background: var(--mint);
    color: var(--color-brand);
    font-size: 1.75rem;
  }

  &__service strong,
  &__service small {
    display: block;
  }

  &__service strong {
    color: var(--ink);
    font-family: var(--font-display);
    font-size: 1.05rem;
  }

  &__service small {
    margin-top: 4px;
    color: var(--ink-soft);
    font-size: 0.7rem;
    font-weight: 750;
  }

  &__marker {
    position: absolute;
    z-index: 3;
    display: grid;
    place-items: center;
    width: 46px;
    height: 46px;
    border: 1px solid rgb(18 98 93 / 15%);
    border-radius: 15px;
    background: white;
    box-shadow: var(--shadow-sm);
    color: var(--color-brand);
    font-size: 1.2rem;
  }

  &__marker--location {
    top: 10%;
    right: 8%;
    transform: rotate(7deg);
  }

  &__marker--people {
    bottom: 14%;
    left: 1%;
    transform: rotate(-8deg);
  }

  &__marker--spark {
    right: 1%;
    bottom: 4%;
    width: 38px;
    height: 38px;
    border-radius: 13px;
    background: #fff0ce;
    color: #8d5a00;
    font-size: 1rem;
    transform: rotate(10deg);
  }
}

@media (width <= 760px) {
  .service-hub-empty {
    grid-template-columns: 1fr;

    &__visual {
      min-height: 260px;
    }

    &__orbit {
      width: min(82vw, 280px);
    }
  }
}

@media (width <= 480px) {
  .service-hub-empty {
    &__actions {
      display: grid;
    }

    &__visual {
      min-height: 230px;
    }
  }
}
</style>
