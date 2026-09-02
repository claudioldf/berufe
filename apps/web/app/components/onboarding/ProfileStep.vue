<script setup lang="ts">
import { computed, ref, useTemplateRef } from "vue";
import type {
  ProfessionalProfileDraft,
  ProfessionalProfilePhotoState,
} from "~/types";
import type { ProfessionalProfileValidation } from "~/composables/useProfessionalProfileDraft";
import { validateOnboardingProfile } from "~/composables/useProfessionalOnboarding";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";

const props = withDefaults(
  defineProps<{
    draft: ProfessionalProfileDraft;
    saving?: boolean;
    serverError?: string;
    photo?: ProfessionalProfilePhotoState;
    photoUploading?: boolean;
    photoError?: string;
  }>(),
  {
    saving: false,
    serverError: "",
    photo: undefined,
    photoUploading: false,
    photoError: "",
  },
);
const emit = defineEmits<{
  complete: [draft: ProfessionalProfileDraft];
  photoSelect: [file: File];
  photoRetry: [];
}>();

const form = ref<ProfessionalProfileDraft>({
  ...props.draft,
  selectedServices: [...props.draft.selectedServices],
  serviceNotes: { ...props.draft.serviceNotes },
  selectedNeighborhoodCodes: [...props.draft.selectedNeighborhoodCodes],
});
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const validation = computed(() => {
  const photoReady = Boolean(props.photo?.hasPhoto || props.photo?.current);
  return validateOnboardingProfile(form.value, photoReady);
});
const isValid = computed(() =>
  Object.values(validation.value).every((fieldError) => !fieldError),
);
const { validationAttempted, revealValidation } =
  useInlineFormValidation(formRoot);
const displayedErrors = computed(() =>
  validationAttempted.value ? validation.value : undefined,
);
const identityErrors = computed<
  ProfessionalProfileValidation["identity"] | undefined
>(() => {
  if (!displayedErrors.value) return undefined;
  return {
    name: displayedErrors.value.name,
    birthdate: displayedErrors.value.birthdate,
    whatsapp: "",
    headline: "",
    bio: "",
    yearsExperience: "",
  };
});
const error = computed(
  () =>
    (validationAttempted.value
      ? Object.values(validation.value).find(Boolean)
      : "") ?? "",
);
const photoError = computed(
  () => props.photoError || displayedErrors.value?.photo || "",
);
const savingReason = computed(() =>
  props.saving ? "Aguarde o salvamento desta etapa terminar." : null,
);

function submit() {
  if (!revealValidation(isValid.value)) return;
  emit("complete", {
    ...form.value,
    selectedServices: [...form.value.selectedServices],
    serviceNotes: { ...form.value.serviceNotes },
    selectedNeighborhoodCodes: [...form.value.selectedNeighborhoodCodes],
  });
}
</script>

<template>
  <section aria-labelledby="onboarding-profile-title">
    <header class="onboarding-step-heading">
      <DesignSystemEyebrow>Etapa 1 de 3</DesignSystemEyebrow>
      <h2 id="onboarding-profile-title">Conte-nos sobre você.</h2>
      <p>
        Essas informações ajudam clientes a entender rapidamente quem você é e
        como entrar em contato.
      </p>
    </header>

    <form
      ref="formRoot"
      class="onboarding-step-form"
      novalidate
      @submit.prevent="submit"
    >
      <p
        v-if="error || props.serverError"
        class="onboarding-step-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" /> {{ error || props.serverError }}
      </p>
      <DashboardProfileFormLayout>
        <DashboardProfileIdentitySection
          v-model="form"
          :photo="props.photo"
          :photo-uploading="props.photoUploading"
          :photo-error="photoError"
          :errors="identityErrors"
          @photo-select="emit('photoSelect', $event)"
          @photo-retry="emit('photoRetry')"
        />
      </DashboardProfileFormLayout>
      <footer class="onboarding-step-actions onboarding-step-actions--end">
        <DesignSystemDisabledTooltip
          :reason="savingReason"
          :loading="props.saving"
        >
          <UButton
            type="submit"
            color="primary"
            trailing-icon="i-lucide-arrow-right"
            :loading="props.saving"
            :disabled="props.saving"
          >
            Salvar e continuar
          </UButton>
        </DesignSystemDisabledTooltip>
      </footer>
    </form>
  </section>
</template>
