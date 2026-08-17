<script setup lang="ts">
import { reactive, shallowRef, watch } from "vue";
import type { PortfolioItemDraft } from "~/types";
import { validateOnboardingImage } from "~/composables/useProfessionalOnboarding";

const props = withDefaults(
  defineProps<{
    serviceOptions: string[];
    submitLabel?: string;
    showCancel?: boolean;
    submitting?: boolean;
  }>(),
  {
    submitLabel: "Enviar para análise",
    showCancel: false,
    submitting: false,
  },
);
const emit = defineEmits<{
  cancel: [];
  submitted: [draft: PortfolioItemDraft];
}>();

const file = shallowRef<File | null>(null);
const title = shallowRef("");
const service = shallowRef("");
const description = shallowRef("");
const errors = reactive({ file: "", title: "", service: "" });

watch(
  () => props.serviceOptions,
  (options) => {
    if (!options.includes(service.value)) service.value = options[0] ?? "";
  },
  { immediate: true },
);

function selectFile(event: Event) {
  file.value = (event.target as HTMLInputElement).files?.[0] ?? null;
  errors.file = validateOnboardingImage(file.value).error;
}

function reset() {
  file.value = null;
  title.value = "";
  service.value = props.serviceOptions[0] ?? "";
  description.value = "";
  errors.file = "";
  errors.title = "";
  errors.service = "";
}

function submit() {
  const fileValidation = validateOnboardingImage(file.value);
  errors.file = fileValidation.error;
  errors.title = title.value.trim() ? "" : "Informe o título do trabalho.";
  errors.service = service.value ? "" : "Selecione o serviço realizado.";
  if (!fileValidation.valid || errors.title || errors.service || !file.value) {
    return;
  }

  emit("submitted", {
    file: file.value,
    title: title.value.trim(),
    service: service.value,
    description: description.value.trim(),
  });
  reset();
}
</script>

<template>
  <form class="portfolio-upload" @submit.prevent="submit">
    <label class="portfolio-upload__drop">
      <UIcon :name="file ? 'i-lucide-file-check-2' : 'i-lucide-cloud-upload'" />
      <strong>{{ file ? file.name : "Selecione uma foto do trabalho" }}</strong>
      <small>JPG ou PNG · até 10 MB</small>
      <input
        name="portfolio-image"
        type="file"
        accept="image/jpeg,image/png"
        :aria-describedby="errors.file ? 'portfolio-image-error' : undefined"
        :aria-invalid="Boolean(errors.file)"
        required
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
        @click="$emit('cancel')"
      >
        Cancelar
      </UButton>
      <UButton
        type="submit"
        color="primary"
        :loading="props.submitting"
        :disabled="props.submitting || !file || !title.trim() || !service"
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
