<script setup lang="ts">
import quotesData from "@data/quotes.json";
import professionalsData from "@data/professionals.json";
import type { Professional, Quote } from "~/types";
import { useToast } from "~/composables/useToast";

const { showToast } = useToast();
const professional = (professionalsData as Professional[])[0]!;
const quote = quotesData.default as Quote;

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Novo orçamento",
  robots: "noindex, nofollow",
});

function handleShared(method: "whatsapp" | "copy") {
  if (method === "copy") return;
  showToast({
    title: "Abrindo o WhatsApp",
    description: "O link seguro foi criado; a Berufe não confirma a entrega.",
  });
}
</script>

<template>
  <div class="quote-workspace">
    <section class="quote-workspace__heading">
      <DesignSystemContainer class="quote-workspace__heading-inner">
        <NuxtLink to="/app/professional"
          ><UIcon name="i-lucide-arrow-left" /> Voltar ao painel</NuxtLink
        >
        <div>
          <div>
            <DesignSystemEyebrow tone="inverse"
              >Berufe Ferramentas</DesignSystemEyebrow
            >
            <h1>
              Novo orçamento <em>#{{ quote.number }}</em>
            </h1>
            <p>Crie, revise e compartilhe um link seguro com seu cliente.</p>
          </div>
          <span><DesignSystemStatusDot /> Rascunho</span>
        </div>
      </DesignSystemContainer>
    </section>
    <DesignSystemContainer class="quote-workspace__content">
      <DashboardQuoteBuilder
        :initial-quote="quote"
        :professional="professional"
        @shared="handleShared"
      />
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.quote-workspace {
  min-height: 100vh;
  padding-bottom: 80px;
  background: var(--color-surface-canvas);
  &__heading {
    padding: 28px 0 34px;
    background: var(--color-brand-strong);
    color: white;
  }
  &__heading a {
    display: flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 20px;
    color: rgb(255 255 255 / 58%);
    font-size: 0.84rem;
    font-weight: 700;
    text-decoration: none;
  }
  &__heading-inner > div {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 20px;
  }
  &__heading .eyebrow {
    margin-bottom: 7px;
  }
  &__heading h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2.5rem;
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  &__heading h1 em {
    color: var(--color-brand-muted);
    font-size: 0.55em;
    font-style: normal;
  }
  &__heading p:last-child {
    margin: 7px 0 0;
    color: rgb(255 255 255 / 58%);
    font-size: 0.82rem;
  }
  &__heading-inner > div > span {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 7px 10px;
    border: 1px solid rgb(255 255 255 / 15%);
    border-radius: 8px;
    color: #d5ddd9;
    font-size: 0.84rem;
    font-weight: 850;
  }
  &__content {
    padding-top: 24px;
  }
}
</style>
