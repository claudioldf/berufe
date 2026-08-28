<script setup lang="ts">
import { shallowRef } from "vue";
import type { VerificationSubmission } from "~/types";
import { validateOnboardingImage } from "~/composables/useProfessionalOnboarding";

const props = withDefaults(
  defineProps<{
    submitLabel?: string;
    submitting?: boolean;
    formId?: string;
    showSubmit?: boolean;
  }>(),
  {
    submitLabel: "Enviar imagem para análise",
    submitting: false,
    formId: undefined,
    showSubmit: true,
  },
);
const emit = defineEmits<{
  submitted: [submission: VerificationSubmission];
  selectionChanged: [hasFile: boolean];
}>();

const file = shallowRef<File | null>(null);
const error = shallowRef("");

function selectFile(event: Event) {
  file.value = (event.target as HTMLInputElement).files?.[0] ?? null;
  error.value = validateOnboardingImage(file.value).error;
  emit("selectionChanged", Boolean(file.value));
}

function submit() {
  const validation = validateOnboardingImage(file.value);
  error.value = validation.error;
  if (!validation.valid || !file.value) return;
  emit("submitted", { file: file.value, kind: "identity" });
  file.value = null;
  error.value = "";
  emit("selectionChanged", false);
}
</script>

<template>
  <form
    :id="props.formId"
    class="identity-upload-form"
    @submit.prevent="submit"
  >
    <header>
      <div>
        <h3>Confirmar sua identidade</h3>
        <p>
          Envie uma foto do seu RG, CNH ou documento de identidade com nome
          completo, data de nascimento e foto.
        </p>
      </div>
      <span><UIcon name="i-lucide-lock-keyhole" /> Arquivo protegido</span>
    </header>
    <label class="verification-upload">
      <input
        name="identity-document"
        type="file"
        accept="image/jpeg,image/png"
        :aria-describedby="error ? 'identity-document-error' : undefined"
        :aria-invalid="Boolean(error)"
        required
        :disabled="props.submitting"
        @change="selectFile"
      />
      <UIcon :name="file ? 'i-lucide-file-check-2' : 'i-lucide-file-up'" />
      <span>
        <strong>{{
          file ? file.name : "Selecione a imagem do documento"
        }}</strong>
        <small>{{
          file ? "Pronta para envio protegido" : "JPG ou PNG · até 10 MB"
        }}</small>
      </span>
      <em>{{ file ? "Trocar" : "Escolher arquivo" }}</em>
    </label>
    <p
      v-if="error"
      id="identity-document-error"
      class="identity-upload-form__error"
      role="alert"
    >
      {{ error }}
    </p>
    <UButton
      v-if="props.showSubmit"
      type="submit"
      color="primary"
      :loading="props.submitting"
      :disabled="props.submitting || !file"
    >
      {{ submitLabel }}
    </UButton>
  </form>
</template>

<style scoped lang="scss">
.identity-upload-form {
  display: grid;

  & header {
    display: flex;
    justify-content: space-between;
    gap: 20px;
    padding-bottom: 18px;
    border-bottom: 1px solid var(--line);
  }
  & h3 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 1.25rem;
  }
  & header p {
    max-width: 100%;
    margin: 5px 0 0;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }
  & header > span {
    display: flex;
    align-items: center;
    gap: 5px;
    color: var(--color-brand);
    font-size: 0.84rem;
    font-weight: 850;
    white-space: nowrap;
  }
  &__error {
    margin: -8px 0 16px;
    color: var(--color-danger);
    font-size: 0.84rem;
    font-weight: 700;
  }
  & > button {
    justify-self: end;
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
  color: var(--color-brand);
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
  color: var(--color-brand);
  font-size: 0.84rem;
  font-style: normal;
  font-weight: 850;
}

@media (width <= 700px) {
  .identity-upload-form header {
    display: grid;
  }
}
</style>
