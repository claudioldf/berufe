<script setup lang="ts">
import { reactive, shallowRef, useTemplateRef, watch } from "vue";
import type {
  PortfolioItemUpdateDraft,
  ProfessionalPortfolioItem,
} from "~/types";
import { useImagePreview } from "~/composables/useImagePreview";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";
import { validateOnboardingImage } from "~/composables/useProfessionalOnboarding";

const props = withDefaults(
  defineProps<{
    serviceOptions: string[];
    submitLabel?: string;
    showCancel?: boolean;
    submitting?: boolean;
    imageRequired?: boolean;
    resetOnSubmit?: boolean;
    initialValues?: Pick<
      ProfessionalPortfolioItem,
      "title" | "service" | "description"
    >;
  }>(),
  {
    submitLabel: "Adicionar ao perfil",
    showCancel: false,
    submitting: false,
    imageRequired: true,
    resetOnSubmit: true,
    initialValues: undefined,
  },
);
const emit = defineEmits<{
  cancel: [];
  submitted: [draft: PortfolioItemUpdateDraft];
}>();

const file = shallowRef<File | null>(null);
const title = shallowRef("");
const service = shallowRef("");
const description = shallowRef("");
const errors = reactive({ file: "", title: "", service: "" });
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const { revealValidation, resetValidation } = useInlineFormValidation(formRoot);
const { previewUrl, setPreviewFile, clearPreview } = useImagePreview();

watch(
  [() => props.initialValues, () => props.serviceOptions],
  ([initialValues, options]) => {
    title.value = initialValues?.title ?? "";
    description.value = initialValues?.description ?? "";
    service.value =
      initialValues && options.includes(initialValues.service)
        ? initialValues.service
        : (options[0] ?? "");
  },
  { immediate: true },
);

function selectFile(event: Event) {
  file.value = (event.target as HTMLInputElement).files?.[0] ?? null;
  const validation = validateOnboardingImage(file.value);
  errors.file = validation.error;
  setPreviewFile(validation.valid ? file.value : null);
}

function reset() {
  clearPreview();
  file.value = null;
  title.value = props.initialValues?.title ?? "";
  service.value =
    props.initialValues &&
    props.serviceOptions.includes(props.initialValues.service)
      ? props.initialValues.service
      : (props.serviceOptions[0] ?? "");
  description.value = props.initialValues?.description ?? "";
  errors.file = "";
  errors.title = "";
  errors.service = "";
  resetValidation();
}

function cancel() {
  reset();
  emit("cancel");
}

function submit() {
  const selectedFile = file.value;
  const fileValidation = selectedFile
    ? validateOnboardingImage(selectedFile)
    : {
        valid: !props.imageRequired,
        error: props.imageRequired ? "Selecione uma imagem JPG ou PNG." : "",
      };
  errors.file = fileValidation.error;
  errors.title = title.value.trim() ? "" : "Informe o título do trabalho.";
  errors.service = service.value ? "" : "Selecione o serviço realizado.";
  const valid = Boolean(
    fileValidation.valid && !errors.title && !errors.service,
  );
  if (!revealValidation(valid)) return;

  emit("submitted", {
    file: selectedFile,
    title: title.value.trim(),
    service: service.value,
    description: description.value.trim(),
  });
  if (props.resetOnSubmit) reset();
}
</script>

<template>
  <form
    ref="formRoot"
    class="portfolio-upload"
    novalidate
    @submit.prevent="submit"
  >
    <label
      class="portfolio-upload__drop"
      :class="{ 'portfolio-upload__drop--invalid': errors.file }"
    >
      <img
        v-if="previewUrl"
        class="portfolio-upload__preview"
        :src="previewUrl"
        :alt="`Prévia de ${file?.name ?? 'foto do trabalho'}`"
      />
      <UIcon
        v-else
        :name="file ? 'i-lucide-file-check-2' : 'i-lucide-cloud-upload'"
      />
      <strong>{{
        file
          ? file.name
          : props.imageRequired
            ? "Selecione uma foto do trabalho"
            : "Adicionar uma nova foto (opcional)"
      }}</strong>
      <small v-if="props.imageRequired">JPG ou PNG · até 10 MB</small>
      <small v-else>
        Selecione JPG ou PNG até 10 MB, ou mantenha a foto atual.
      </small>
      <input
        name="portfolio-image"
        type="file"
        accept="image/jpeg,image/png"
        :aria-describedby="errors.file ? 'portfolio-image-error' : undefined"
        :aria-invalid="Boolean(errors.file)"
        :required="props.imageRequired"
        @change="selectFile"
      />
    </label>
    <p
      v-if="errors.file"
      id="portfolio-image-error"
      class="portfolio-upload__error"
      role="alert"
    >
      {{ errors.file }}
    </p>
    <DesignSystemFormField
      id="portfolio-title"
      v-slot="field"
      label="Título do trabalho"
      :error="errors.title"
      required
    >
      <input
        :id="field.controlId"
        v-model="title"
        name="portfolio-title"
        required
        maxlength="80"
        autocomplete="off"
        placeholder="Ex.: Iluminação da cozinha…"
        :aria-describedby="field.describedBy"
        :aria-invalid="field.invalid"
        @input="errors.title = ''"
      />
    </DesignSystemFormField>
    <DesignSystemFormField
      id="portfolio-service"
      v-slot="field"
      label="Serviço"
      :error="errors.service"
      required
    >
      <select
        :id="field.controlId"
        v-model="service"
        name="portfolio-service"
        required
        :aria-describedby="field.describedBy"
        :aria-invalid="field.invalid"
        @change="errors.service = ''"
      >
        <option disabled value="">Selecione um serviço</option>
        <option v-for="option in serviceOptions" :key="option">
          {{ option }}
        </option>
      </select>
    </DesignSystemFormField>
    <DesignSystemFormField
      id="portfolio-description"
      v-slot="field"
      label="Descrição opcional"
    >
      <textarea
        :id="field.controlId"
        v-model="description"
        name="portfolio-description"
        maxlength="300"
        placeholder="Explique brevemente o que foi feito…"
        :aria-describedby="field.describedBy"
      />
    </DesignSystemFormField>
    <footer class="portfolio-upload__actions">
      <UButton
        v-if="showCancel"
        type="button"
        color="neutral"
        variant="ghost"
        :disabled="props.submitting"
        @click="cancel"
      >
        Cancelar
      </UButton>
      <UButton
        type="submit"
        color="primary"
        :loading="props.submitting"
        :disabled="props.submitting"
      >
        {{ submitLabel }}
      </UButton>
    </footer>
  </form>
</template>

<style scoped lang="scss">
.portfolio-upload {
  display: grid;
  gap: 14px;

  &__drop {
    position: relative;
    display: grid;
    gap: 6px;
    padding: 30px;
    border: 1px dashed #8eb6aa;
    border-radius: 13px;
    background: var(--color-brand-tint-subtle);
    color: var(--ink);
    font-size: 0.86rem;
    font-weight: 800;
    text-align: center;
    cursor: pointer;
    place-items: center;
  }
  &__drop svg {
    color: var(--color-brand);
    font-size: 1.8rem;
  }
  &__drop small {
    color: var(--ink-soft);
  }
  &__drop input {
    position: absolute;
    inset: 0;
    opacity: 0;
    cursor: pointer;
  }
  &__drop--invalid {
    border-color: var(--color-danger);
    background: var(--color-danger-tint);
  }
  &__drop--invalid:focus-within {
    box-shadow: 0 0 0 3px rgb(180 35 24 / 16%);
  }
  &__preview {
    width: 100%;
    max-height: 260px;
    border-radius: 10px;
    object-fit: cover;
  }
  &__error {
    margin: -6px 0 0;
    color: var(--color-danger);
    font-size: 0.84rem;
    font-weight: 700;
  }
  &__actions {
    display: flex;
    justify-content: flex-end;
    gap: 8px;
    margin-top: 4px;
  }
}
</style>
