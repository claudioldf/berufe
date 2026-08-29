<script setup lang="ts">
import AccountErasureForm from "~/components/account/AccountErasureForm.vue";
import { useProfessionalDataErasure } from "~/composables/useProfessionalDataErasure";

const erasure = useProfessionalDataErasure();

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Excluir conta",
  robots: "noindex, nofollow",
});

async function submit() {
  const result = await erasure.submit();
  if (!result) return;

  await navigateTo(
    "/exclusao-de-conta/" + encodeURIComponent(result.statusToken),
    { replace: true },
  );
}
</script>

<template>
  <div class="account-exclusion-page">
    <header class="account-exclusion-page__header">
      <DesignSystemContainer>
        <DesignSystemEyebrow>Exclusão de conta</DesignSystemEyebrow>
        <h1>Excluir sua conta permanentemente.</h1>
        <p>
          Confira o que será removido e quais registros mínimos precisam
          permanecer antes de confirmar a exclusão irreversível.
        </p>
      </DesignSystemContainer>
    </header>

    <DesignSystemContainer class="account-exclusion-page__content">
      <AccountErasureForm
        :submitting="erasure.submitting.value"
        :error="erasure.error.value"
        @submit="submit"
      />
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.account-exclusion-page {
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
