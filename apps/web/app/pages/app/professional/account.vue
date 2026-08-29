<script setup lang="ts">
import AccountErasureForm from "~/components/account/AccountErasureForm.vue";
import { useProfessionalDataErasure } from "~/composables/useProfessionalDataErasure";
import { professionalReauthenticationPath } from "~/utils/professional-auth";

const erasure = useProfessionalDataErasure();

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Conta e privacidade",
  robots: "noindex, nofollow",
});

async function reauthenticate() {
  await navigateTo(professionalReauthenticationPath);
}

async function submit(confirmation: string) {
  const result = await erasure.submit(confirmation);
  if (!result) return;

  await navigateTo(
    "/exclusao-de-conta/" + encodeURIComponent(result.statusToken),
    { replace: true },
  );
}
</script>

<template>
  <div class="account-page">
    <header class="account-page__header">
      <DesignSystemContainer>
        <DesignSystemEyebrow>Conta e privacidade</DesignSystemEyebrow>
        <h1>Controle os dados da sua conta.</h1>
        <p>
          Revise as consequências e use o fluxo protegido por SMS quando quiser
          encerrar definitivamente sua presença na Berufe.
        </p>
      </DesignSystemContainer>
    </header>

    <DesignSystemContainer class="account-page__content">
      <AccountErasureForm
        :recently-verified="erasure.isRecentlyVerified.value"
        :submitting="erasure.submitting.value"
        :error="erasure.error.value"
        @reauthenticate="reauthenticate"
        @submit="submit"
      />
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.account-page {
  min-height: calc(100vh - 76px);
  background: var(--color-surface-canvas);

  &__header {
    padding: clamp(38px, 7vw, 72px) 0;
    background: var(--color-brand-strong);
    color: white;
  }

  &__header h1 {
    max-width: 720px;
    margin: 10px 0 14px;
    font-family: var(--font-display);
    font-size: clamp(2.4rem, 6vw, 4.4rem);
    font-weight: 500;
    letter-spacing: -0.05em;
    line-height: 0.98;
  }

  &__header p {
    max-width: 680px;
    margin: 0;
    color: rgb(255 255 255 / 72%);
    line-height: 1.7;
  }

  &__content {
    width: min(100% - 28px, 860px);
    padding-top: clamp(28px, 5vw, 56px);
    padding-bottom: clamp(50px, 8vw, 90px);
  }
}
</style>
