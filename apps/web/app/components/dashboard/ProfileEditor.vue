<script setup lang="ts">
import type {
  Professional,
  ProfessionalProfileDraft,
  ProfessionalProfilePhotoState,
  Service,
} from "~/types";
import { useProfessionalProfileDraft } from "~/composables/useProfessionalProfileDraft";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";

const props = defineProps<{
  professional: Professional;
  services: Service[];
  saving?: boolean;
  photo?: ProfessionalProfilePhotoState;
  photoUploading?: boolean;
  photoRemoving?: boolean;
  photoError?: string;
}>();
const emit = defineEmits<{
  save: [draft: ProfessionalProfileDraft, confirm: () => void];
  photoSelect: [file: File];
  photoRetry: [];
  photoRemove: [];
}>();
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");

const {
  form,
  saved,
  socialErrors,
  validation,
  isValid,
  markDirty,
  validateSocialField,
  clearSocialError,
  toggleService,
  commit,
  confirmSaved,
} = useProfessionalProfileDraft(() => props.professional);
const { validationAttempted, revealValidation, resetValidation } =
  useInlineFormValidation(formRoot);
const identityErrors = computed(() =>
  validationAttempted.value ? validation.value.identity : undefined,
);
const displayedSocialErrors = computed(() => ({
  instagram:
    socialErrors.instagram ||
    (validationAttempted.value ? validation.value.social.instagram : ""),
  youtube:
    socialErrors.youtube ||
    (validationAttempted.value ? validation.value.social.youtube : ""),
}));
const servicesError = computed(() =>
  validationAttempted.value ? validation.value.services : "",
);
const coverageError = computed(() =>
  validationAttempted.value ? validation.value.coverage : "",
);

watch(
  () => props.professional.id,
  () => resetValidation(),
);

function save() {
  if (!revealValidation(isValid.value)) return;
  const draft = commit();
  if (draft) emit("save", draft, confirmSaved);
}
</script>

<template>
  <form
    ref="formRoot"
    class="profile-editor"
    novalidate
    @input="markDirty"
    @submit.prevent="save"
  >
    <DashboardProfileFormLayout>
      <DashboardProfileIdentitySection
        v-model="form"
        :photo="props.photo"
        :photo-uploading="props.photoUploading"
        :photo-removing="props.photoRemoving"
        allow-photo-removal
        :photo-error="props.photoError"
        :errors="identityErrors"
        @photo-select="emit('photoSelect', $event)"
        @photo-retry="emit('photoRetry')"
        @photo-remove="emit('photoRemove')"
      />
      <DashboardProfileSocialSection
        v-model="form"
        :errors="displayedSocialErrors"
        @clear="clearSocialError"
        @validate="validateSocialField"
      />
      <DashboardProfileServicesSection
        v-model="form"
        :services="props.services"
        :error="servicesError"
        @toggle="toggleService"
      />
      <DashboardProfileCoverageSection
        v-model="form"
        :error="coverageError"
        @dirty="markDirty"
      />
    </DashboardProfileFormLayout>
    <DashboardProfileSaveBar
      :saved="saved"
      :saving="props.saving"
      :valid="isValid"
      :validation-attempted="validationAttempted"
    />
  </form>
</template>

<style scoped lang="scss">
.profile-editor {
  display: grid;
  gap: 18px;
}

:deep() {
  .editor-savebar {
    position: sticky;
    z-index: 20;
    bottom: 14px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 15px;
    padding: 12px 14px;
    border: 1px solid var(--line);
    border-radius: 15px;
    background: rgb(255 255 255 / 95%);
    box-shadow: var(--shadow-lg);
    backdrop-filter: blur(14px);
  }
  .editor-savebar > span {
    display: flex;
    align-items: center;
    gap: 6px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 700;
  }
  .editor-savebar > div {
    display: flex;
    align-items: center;
    gap: 8px;
  }
  @media (width <= 750px) {
    .editor-savebar {
      display: grid;
    }
    .editor-savebar > div {
      justify-content: stretch;
    }
    .editor-savebar > div > * {
      flex: 1;
      justify-content: center;
    }
  }
}
</style>
