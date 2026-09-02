<script setup lang="ts">
import { computed, shallowRef, useTemplateRef } from "vue";
import type { VerificationSubmission } from "~/types";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";
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
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const { revealValidation, resetValidation } = useInlineFormValidation(formRoot);
const submittingReason = computed(() =>
  props.submitting ? "Aguarde o envio do documento terminar." : null,
);

function selectFile(event: Event) {
  file.value = (event.target as HTMLInputElement).files?.[0] ?? null;
  error.value = validateOnboardingImage(file.value).error;
  emit("selectionChanged", Boolean(file.value));
}

function submit() {
  const selectedFile = file.value;
  const validation = validateOnboardingImage(selectedFile);
  error.value = validation.error;
  if (!revealValidation(Boolean(validation.valid && selectedFile))) return;
  if (!selectedFile) return;
  emit("submitted", { file: selectedFile, kind: "identity" });
  file.value = null;
  error.value = "";
  resetValidation();
  emit("selectionChanged", false);
}
</script>

<template>
  <form
    :id="props.formId"
    ref="formRoot"
    class="identity-upload-form"
    novalidate
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
    <label
      class="verification-upload"
      :class="{ 'verification-upload--invalid': error }"
    >
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
    <DesignSystemDisabledTooltip
      v-if="props.showSubmit"
      :reason="submittingReason"
      :loading="props.submitting"
    >
      <UButton
        type="submit"
        color="primary"
        :loading="props.submitting"
        :disabled="props.submitting"
      >
        {{ submitLabel }}
      </UButton>
    </DesignSystemDisabledTooltip>
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
.verification-upload--invalid {
  border-color: var(--color-danger);
  background: var(--color-danger-tint);
}
.verification-upload--invalid:focus-within {
  box-shadow: 0 0 0 3px rgb(180 35 24 / 16%);
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
