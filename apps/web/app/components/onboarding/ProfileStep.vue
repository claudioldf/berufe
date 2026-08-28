<script setup lang="ts">
import { ref, shallowRef } from "vue";
import type {
  ProfessionalProfileDraft,
  ProfessionalProfilePhotoState,
} from "~/types";
import { validateOnboardingProfile } from "~/composables/useProfessionalOnboarding";

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
const error = shallowRef("");

function submit() {
  const photoReady = Boolean(
    props.photo?.hasPublishedPhoto ||
    ["pending_review", "approved"].includes(props.photo?.current?.status ?? ""),
  );
  const errors = validateOnboardingProfile(form.value, photoReady);
  error.value = Object.values(errors).find(Boolean) ?? "";
  if (error.value) return;
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

    <form class="onboarding-step-form" @submit.prevent="submit">
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
          :photo-error="props.photoError"
          @photo-select="emit('photoSelect', $event)"
          @photo-retry="emit('photoRetry')"
        />
      </DashboardProfileFormLayout>
      <footer class="onboarding-step-actions onboarding-step-actions--end">
        <UButton
          type="submit"
          color="primary"
          trailing-icon="i-lucide-arrow-right"
          :loading="props.saving"
          :disabled="props.saving"
        >
          Salvar e continuar
        </UButton>
      </footer>
    </form>
  </section>
</template>
