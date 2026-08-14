<script setup lang="ts">
import { shallowRef } from "vue";
import type { Evidence } from "~/types";

defineProps<{ evidence: Evidence[] }>();
const emit = defineEmits<{ submitted: [] }>();
const hasFile = shallowRef(false);
</script>

<template>
  <div class="verification-panel">
    <DesignSystemSurfaceCard as="section" class="verification-panel__intro"
      ><div>
        <DesignSystemEyebrow>Evidências específicas</DesignSystemEyebrow>
        <h2>Verificações</h2>
        <p>
          Os selos explicam exatamente o que a Berufe conferiu. Eles não são uma
          garantia de serviço.
        </p>
      </div>
      <UIcon name="i-lucide-shield-check"
    /></DesignSystemSurfaceCard>
    <DesignSystemSurfaceCard as="section" class="verification-panel__current"
      ><h3>Selos do seu perfil</h3>
      <div>
        <PublicEvidenceBadge
          v-for="item in evidence"
          :key="item.id"
          :evidence="item"
        /></div
    ></DesignSystemSurfaceCard>
    <DesignSystemSurfaceCard as="section" class="verification-panel__request">
      <header>
        <div>
          <h3>Enviar evidência de identidade</h3>
          <p>
            Envie uma imagem de documento oficial com foto. O arquivo é privado,
            acessível somente à equipe responsável e removido conforme a
            política de retenção.
          </p>
        </div>
        <span><UIcon name="i-lucide-lock-keyhole" /> Arquivo protegido</span>
      </header>
      <label class="verification-upload"
        ><input
          type="file"
          accept="image/jpeg,image/png"
          @change="hasFile = true"
        /><UIcon
          :name="hasFile ? 'i-lucide-file-check-2' : 'i-lucide-file-up'"
        /><span
          ><strong>{{
            hasFile ? "Imagem selecionada" : "Selecione a imagem do documento"
          }}</strong
          ><small>{{
            hasFile ? "Pronta para envio seguro" : "JPG ou PNG · até 10 MB"
          }}</small></span
        ><em>{{ hasFile ? "Trocar" : "Escolher arquivo" }}</em></label
      >
      <UButton
        color="primary"
        :disabled="!hasFile"
        @click="
          emit('submitted');
          hasFile = false;
        "
        >Enviar imagem para análise</UButton
      >
    </DesignSystemSurfaceCard>
  </div>
</template>

<style scoped lang="scss">
.verification-panel {
  display: grid;
  gap: 14px;
  &__intro {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 26px;
  }
  &__intro h2 {
    margin: 0;
    font-family: Georgia, serif;
    font-size: 2rem;
  }
  &__intro p:last-child {
    max-width: 580px;
    margin: 7px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
  }
  &__intro > svg {
    color: #397a69;
    font-size: 3.5rem;
    opacity: 0.25;
  }
  &__current {
    padding: 22px;
  }
  & h3 {
    margin: 0;
    font-family: Georgia, serif;
    font-size: 1.25rem;
  }
  &__current > div {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 15px;
  }
  &__request {
    padding: 22px;
  }
  &__request header {
    display: flex;
    justify-content: space-between;
    gap: 20px;
    padding-bottom: 18px;
    border-bottom: 1px solid var(--line);
  }
  &__request header p {
    max-width: 550px;
    margin: 5px 0 0;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }
  &__request header > span {
    display: flex;
    align-items: center;
    gap: 5px;
    color: #397a69;
    font-size: 0.84rem;
    font-weight: 850;
  }
}
.verification-upload {
  position: relative;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 11px;
  margin: 16px 0;
  padding: 15px;
  border: 1px dashed #98bcb1;
  border-radius: 12px;
  background: #fafcfb;
  cursor: pointer;
}
.verification-upload input {
  position: absolute;
  inset: 0;
  opacity: 0;
  cursor: pointer;
}
.verification-upload > svg {
  color: #397a69;
  font-size: 1.4rem;
}
.verification-upload strong,
.verification-upload small {
  display: block;
}
.verification-upload strong {
  font-size: 0.86rem;
}
.verification-upload small {
  margin-top: 3px;
  color: var(--ink-soft);
  font-size: 0.82rem;
}
.verification-upload em {
  color: #397a69;
  font-size: 0.84rem;
  font-style: normal;
  font-weight: 850;
}
@media (max-width: 700px) {
  .verification-panel {
    &__request header {
      display: grid;
    }
  }
}
</style>
