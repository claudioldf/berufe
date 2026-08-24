<script setup lang="ts">
import type { NuxtError } from "#app";
import { computed } from "vue";

interface Props {
  error: NuxtError;
}

const props = defineProps<Props>();

const statusCode = computed(
  () => props.error.status ?? props.error.statusCode ?? 500,
);
const isNotFound = computed(() => statusCode.value === 404);
const content = computed(() =>
  isNotFound.value
    ? {
        eyebrow: "Página não encontrada",
        title: "Este endereço",
        titleAccent: "não mora mais aqui.",
        description:
          "O link pode ter mudado ou talvez nunca tenha existido. Vamos levar você de volta para um lugar conhecido.",
        note: "Você também pode continuar procurando profissionais em Joinville.",
      }
    : {
        eyebrow: "Algo saiu do lugar",
        title: "Nossa casa precisa",
        titleAccent: "de um pequeno ajuste.",
        description:
          "Não conseguimos abrir esta página agora. Tente novamente — normalmente tudo volta ao lugar em poucos instantes.",
        note: "Se o problema continuar, aguarde alguns minutos antes de tentar de novo.",
      },
);

useSeoMeta({
  title: () => `${statusCode.value} — ${content.value.eyebrow}`,
  description: () => content.value.description,
  robots: "noindex, nofollow",
});
</script>

<template>
  <div class="error-shell" :class="{ 'error-shell--not-found': isNotFound }">
    <a class="error-shell__skip-link" href="#error-content">
      Pular para o conteúdo
    </a>

    <div class="error-shell__glow error-shell__glow--one" aria-hidden="true" />
    <div class="error-shell__glow error-shell__glow--two" aria-hidden="true" />

    <header class="error-shell__header">
      <a class="error-shell__brand" href="/" aria-label="Berufe — início">
        berufe<span>.</span>
      </a>
      <span class="error-shell__status">
        <span class="error-shell__status-dot" aria-hidden="true" />
        Erro {{ statusCode }}
      </span>
    </header>

    <main id="error-content" class="error-shell__main" tabindex="-1">
      <section class="error-shell__copy" aria-labelledby="error-title">
        <p class="error-shell__eyebrow">
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path d="M12 3 4.5 9.2v9.3h15V9.2L12 3Z" />
            <path d="M9.5 18.5v-5h5v5" />
          </svg>
          {{ content.eyebrow }}
        </p>

        <h1 id="error-title" class="error-shell__title">
          {{ content.title }}
          <em>{{ content.titleAccent }}</em>
        </h1>

        <p class="error-shell__description">
          {{ content.description }}
        </p>

        <div v-if="isNotFound" class="error-shell__actions">
          <a class="error-shell__button error-shell__button--primary" href="/">
            Voltar para o início
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="m9 18 6-6-6-6" />
            </svg>
          </a>
          <a
            class="error-shell__button error-shell__button--secondary"
            href="/encontrar"
          >
            Encontrar profissionais
          </a>
        </div>

        <div v-else class="error-shell__actions">
          <a
            class="error-shell__button error-shell__button--primary"
            href=""
            aria-label="Tentar carregar esta página novamente"
          >
            Tentar novamente
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M20 6v5h-5" />
              <path d="M18.5 15a7 7 0 1 1-1-8.5L20 11" />
            </svg>
          </a>
          <a
            class="error-shell__button error-shell__button--secondary"
            href="/"
          >
            Voltar para o início
          </a>
        </div>

        <p class="error-shell__note">
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <circle cx="12" cy="12" r="9" />
            <path d="M12 10v6M12 7h.01" />
          </svg>
          {{ content.note }}
        </p>
      </section>

      <div class="error-shell__visual" aria-hidden="true">
        <span class="error-shell__code">{{ statusCode }}</span>
        <svg class="error-shell__illustration" viewBox="0 0 560 480">
          <circle class="art__halo" cx="280" cy="235" r="188" />
          <circle class="art__sun" cx="430" cy="82" r="28" />
          <path class="art__ground" d="M74 401c88-29 325-29 412 0" />
          <path class="art__plant" d="M112 394c-8-56-28-88-54-106" />
          <path class="art__plant" d="M103 356c-29-4-47-21-51-48" />
          <path class="art__plant" d="M106 373c23-8 38-27 42-55" />

          <path class="art__house" d="M155 213 280 111l125 102v181H155V213Z" />
          <path class="art__roof" d="m130 226 150-123 150 123" />
          <path class="art__chimney" d="M364 155v-53h35v82" />
          <path class="art__door" d="M246 394V277h68v117" />
          <circle class="art__handle" cx="297" cy="338" r="4" />
          <path class="art__window" d="M177 247h43v43h-43z" />
          <path class="art__window-line" d="M198.5 247v43M177 268.5h43" />
          <path class="art__window" d="M340 247h43v43h-43z" />
          <path class="art__window-line" d="M361.5 247v43M340 268.5h43" />

          <g v-if="isNotFound" class="art__not-found">
            <path
              class="art__route"
              d="M81 405c11-53 49-58 81-39 37 21 30 64 82 47"
            />
            <path
              class="art__pin"
              d="M82 277c-25 0-44 19-44 43 0 34 44 72 44 72s44-38 44-72c0-24-19-43-44-43Z"
            />
            <circle class="art__pin-center" cx="82" cy="319" r="12" />
            <path
              class="art__question"
              d="M271 303c2-15 25-17 29-2 4 14-15 16-15 28M285 347h.01"
            />
          </g>

          <g v-else class="art__repair">
            <path class="art__toolbox" d="M345 356h112v57H345z" />
            <path class="art__toolbox-handle" d="M374 356v-24h54v24" />
            <path class="art__toolbox-line" d="M345 377h112" />
            <path
              class="art__wrench"
              d="M428 316c-12-13-10-32 3-43 7-6 15-8 23-6l-15 15 4 14 14 4 15-15c2 8 0 17-6 23-8 8-19 11-29 8l-38 39-12-12 41-27Z"
            />
          </g>
        </svg>
      </div>
    </main>

    <footer class="error-shell__footer">
      <span>Confiança para cuidar da sua casa.</span>
      <span>Joinville, SC</span>
    </footer>
  </div>
</template>

<style scoped lang="scss">
:global(body) {
  margin: 0;
}

.error-shell {
  position: relative;
  display: grid;
  grid-template-rows: auto 1fr auto;
  min-height: 100vh;
  min-height: 100svh;
  overflow: hidden;
  background:
    radial-gradient(circle at 8% 4%, rgb(216 240 231 / 72%), transparent 28rem),
    linear-gradient(135deg, #faf8f3 0%, #f4f2eb 100%);
  color: #17352f;
  font-family: Manrope, "Avenir Next", avenir, sans-serif;

  &::before {
    position: absolute;
    inset: 0;
    background-image: radial-gradient(
      rgb(23 53 47 / 8%) 0.65px,
      transparent 0.65px
    );
    background-size: 14px 14px;
    content: "";
    mask-image: linear-gradient(to bottom, black, transparent 72%);
    pointer-events: none;
  }

  &__skip-link {
    position: fixed;
    top: 12px;
    left: 12px;
    z-index: 20;
    padding: 10px 14px;
    border-radius: 10px;
    background: white;
    color: #17352f;
    font-weight: 800;
    transform: translateY(-160%);
    transition: transform 0.15s ease;
  }

  &__skip-link:focus-visible {
    transform: translateY(0);
  }

  &__header,
  &__main,
  &__footer {
    position: relative;
    z-index: 2;
    width: min(1180px, calc(100% - 80px));
    margin-inline: auto;
  }

  &__header {
    display: flex;
    min-height: 104px;
    align-items: center;
    justify-content: space-between;
  }

  &__brand {
    color: inherit;
    font-family: georgia, "Times New Roman", serif;
    font-size: 1.9rem;
    font-weight: 700;
    letter-spacing: -0.045em;
    line-height: 1;
    text-decoration: none;
  }

  &__brand span {
    color: #f8755d;
  }

  &__status {
    display: inline-flex;
    align-items: center;
    gap: 9px;
    padding: 9px 13px;
    border: 1px solid rgb(23 53 47 / 12%);
    border-radius: 999px;
    background: rgb(255 255 255 / 58%);
    color: #59706a;
    font-size: 0.72rem;
    font-weight: 800;
    letter-spacing: 0.09em;
    text-transform: uppercase;
    backdrop-filter: blur(10px);
  }

  &__status-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: #f8755d;
    box-shadow: 0 0 0 4px rgb(248 117 93 / 14%);
  }

  &__main {
    display: grid;
    grid-template-columns: minmax(0, 0.88fr) minmax(420px, 1.12fr);
    align-items: center;
    gap: clamp(40px, 7vw, 96px);
    padding-block: 36px 68px;
  }

  &__copy {
    max-width: 610px;
  }

  &__eyebrow {
    display: flex;
    align-items: center;
    gap: 9px;
    margin: 0 0 22px;
    color: #12625d;
    font-size: 0.75rem;
    font-weight: 800;
    letter-spacing: 0.14em;
    text-transform: uppercase;
  }

  &__eyebrow svg,
  &__note svg {
    width: 19px;
    fill: none;
    stroke: currentcolor;
    stroke-linecap: round;
    stroke-linejoin: round;
    stroke-width: 1.8;
  }

  &__title {
    max-width: 620px;
    margin: 0;
    font-family: Newsreader, georgia, "Times New Roman", serif;
    font-size: clamp(3.25rem, 6.3vw, 5.75rem);
    font-weight: 500;
    letter-spacing: -0.055em;
    line-height: 0.96;
  }

  &__title em {
    display: block;
    color: #12625d;
    font-weight: inherit;
  }

  &__description {
    max-width: 560px;
    margin: 28px 0 0;
    color: #59706a;
    font-size: 1.04rem;
    line-height: 1.75;
  }

  &__actions {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-top: 34px;
  }

  &__button {
    display: inline-flex;
    min-height: 50px;
    align-items: center;
    justify-content: center;
    gap: 10px;
    padding: 0 20px;
    border: 1px solid transparent;
    border-radius: 12px;
    font-size: 0.86rem;
    font-weight: 800;
    text-decoration: none;
    transition:
      transform 0.18s ease,
      background-color 0.18s ease,
      box-shadow 0.18s ease;
  }

  &__button:hover {
    transform: translateY(-2px);
  }

  &__button:focus-visible,
  &__brand:focus-visible {
    outline: 2px solid #3f8372;
    outline-offset: 4px;
  }

  &__button svg {
    width: 17px;
    fill: none;
    stroke: currentcolor;
    stroke-linecap: round;
    stroke-linejoin: round;
    stroke-width: 2;
  }

  &__button--primary {
    background: #17352f;
    box-shadow: 0 12px 28px rgb(23 53 47 / 17%);
    color: white;
  }

  &__button--primary:hover {
    background: #12625d;
    box-shadow: 0 16px 32px rgb(23 53 47 / 22%);
  }

  &__button--secondary {
    border-color: rgb(23 53 47 / 16%);
    background: rgb(255 255 255 / 52%);
    color: #17352f;
    backdrop-filter: blur(8px);
  }

  &__button--secondary:hover {
    background: white;
  }

  &__note {
    display: flex;
    max-width: 520px;
    align-items: flex-start;
    gap: 9px;
    margin: 28px 0 0;
    color: #82928d;
    font-size: 0.78rem;
    line-height: 1.55;
  }

  &__note svg {
    width: 16px;
    flex: 0 0 auto;
    margin-top: 1px;
  }

  &__visual {
    position: relative;
    min-width: 0;
  }

  &__code {
    position: absolute;
    top: -24px;
    right: 3%;
    z-index: -1;
    color: rgb(23 53 47 / 6%);
    font-family: Newsreader, georgia, "Times New Roman", serif;
    font-size: clamp(8rem, 18vw, 14rem);
    font-weight: 700;
    letter-spacing: -0.08em;
    line-height: 1;
    user-select: none;
  }

  &__illustration {
    display: block;
    width: min(100%, 570px);
    margin-inline: auto;
    overflow: visible;
    filter: drop-shadow(0 28px 32px rgb(23 53 47 / 10%));
  }

  &__footer {
    display: flex;
    min-height: 74px;
    align-items: center;
    justify-content: space-between;
    border-top: 1px solid rgb(23 53 47 / 10%);
    color: #82928d;
    font-size: 0.72rem;
    font-weight: 700;
    letter-spacing: 0.04em;
  }

  &__glow {
    position: absolute;
    border-radius: 50%;
    filter: blur(1px);
    pointer-events: none;
  }

  &__glow--one {
    top: -130px;
    right: -110px;
    width: 370px;
    height: 370px;
    border: 1px solid rgb(18 98 93 / 9%);
  }

  &__glow--two {
    right: 36%;
    bottom: -190px;
    width: 320px;
    height: 320px;
    background: rgb(248 117 93 / 5%);
  }
}

.art {
  &__halo {
    fill: #d8f0e7;
  }

  &__sun {
    fill: #f8755d;
  }

  &__ground,
  &__plant,
  &__roof,
  &__chimney,
  &__door,
  &__window,
  &__window-line,
  &__route,
  &__pin,
  &__question,
  &__toolbox,
  &__toolbox-handle,
  &__toolbox-line,
  &__wrench {
    fill: none;
    stroke: #17352f;
    stroke-linecap: round;
    stroke-linejoin: round;
  }

  &__ground,
  &__plant {
    stroke-width: 5;
  }

  &__house {
    fill: #fffdfa;
    stroke: #17352f;
    stroke-linejoin: round;
    stroke-width: 7;
  }

  &__roof,
  &__chimney,
  &__door,
  &__window {
    stroke-width: 7;
  }

  &__door {
    fill: #b6dfcf;
  }

  &__window {
    fill: #fff0ec;
  }

  &__window-line {
    stroke-width: 4;
  }

  &__handle {
    fill: #f8755d;
  }

  &__route {
    stroke: #f8755d;
    stroke-dasharray: 9 13;
    stroke-width: 5;
  }

  &__pin {
    fill: #f8755d;
    stroke-width: 6;
  }

  &__pin-center {
    fill: #fffdfa;
  }

  &__question {
    stroke: #12625d;
    stroke-width: 8;
  }

  &__toolbox {
    fill: #f8755d;
    stroke-width: 6;
  }

  &__toolbox-handle,
  &__toolbox-line,
  &__wrench {
    stroke-width: 6;
  }

  &__wrench {
    fill: #fffdfa;
  }
}

@media (width <= 940px) {
  .error-shell {
    &__header,
    &__main,
    &__footer {
      width: min(100% - 48px, 720px);
    }

    &__main {
      grid-template-columns: 1fr;
      gap: 24px;
      padding-block: 52px 64px;
    }

    &__copy {
      max-width: 650px;
    }

    &__visual {
      grid-row: 1;
      width: min(72vw, 440px);
      margin-inline: auto;
    }

    &__code {
      top: -12px;
      font-size: clamp(7rem, 25vw, 11rem);
    }

    &__illustration {
      max-height: 370px;
    }
  }
}

@media (width <= 560px) {
  .error-shell {
    &__header,
    &__main,
    &__footer {
      width: calc(100% - 32px);
    }

    &__header {
      min-height: 78px;
    }

    &__brand {
      font-size: 1.6rem;
    }

    &__status {
      padding: 8px 11px;
      font-size: 0.66rem;
    }

    &__main {
      gap: 16px;
      padding-block: 26px 46px;
    }

    &__visual {
      width: min(94vw, 350px);
    }

    &__illustration {
      max-height: 290px;
    }

    &__eyebrow {
      margin-bottom: 16px;
    }

    &__title {
      font-size: clamp(2.85rem, 14vw, 4rem);
    }

    &__description {
      margin-top: 22px;
      font-size: 0.96rem;
      line-height: 1.65;
    }

    &__actions {
      display: grid;
      margin-top: 28px;
    }

    &__button {
      width: 100%;
    }

    &__note {
      margin-top: 24px;
    }

    &__footer {
      min-height: 68px;
    }

    &__footer span:first-child {
      display: none;
    }
  }
}

@media (prefers-reduced-motion: reduce) {
  .error-shell__button,
  .error-shell__skip-link {
    transition: none;
  }
}
</style>
