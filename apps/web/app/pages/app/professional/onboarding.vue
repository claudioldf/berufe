<script setup lang="ts">
import { computed } from "vue";
import { useCatalogs } from "~/composables/useCatalogs";
import type { ProfessionalProfileDraft } from "~/types";

definePageMeta({ layout: "workspace" });

const { data: catalog, error: catalogError } = await useCatalogs();
if (catalogError.value || !catalog.value) {
  throw createError({
    statusCode: 503,
    statusMessage: "Catálogo temporariamente indisponível.",
  });
}
const services = computed(() => catalog.value?.services ?? []);
const {
  data: workspace,
  error: workspaceError,
  saveIdentity,
  saveSupply,
  photoUploading,
  photoError,
  uploadPhoto,
  retryPhoto,
  createVerificationRequest,
  submissionSaving,
  submissionError,
  submitProfile,
} = await useProfessionalWorkspace();
if (workspaceError.value || !workspace.value) {
  throw createError({
    statusCode: 503,
    statusMessage: "Seu perfil está temporariamente indisponível.",
  });
}
const professionalWorkspace = computed(() => workspace.value!);

async function saveOnboardingIdentity(draft: ProfessionalProfileDraft) {
  const updated = await saveIdentity(draft);
  return {
    ...draft,
    ...updated.profile.identity,
  };
}

async function saveOnboardingSupply(draft: ProfessionalProfileDraft) {
  const updated = await saveSupply(draft, services.value);
  const selections = updated.profile.services;
  return {
    ...draft,
    selectedServices: selections.map((selection) => selection.name),
    primaryService:
      selections.find((selection) => selection.isPrimary)?.name ?? "",
    serviceNotes: Object.fromEntries(
      selections.map((selection) => [selection.name, selection.note]),
    ),
    coverageCityCode: updated.profile.coverage.city?.code ?? "",
    coversWholeCity: updated.profile.coverage.wholeCity,
    selectedNeighborhoodCodes: updated.profile.coverage.neighborhoods.map(
      (neighborhood) => neighborhood.code,
    ),
  };
}

async function saveOnboardingVerification(file: File) {
  const updated = await createVerificationRequest(file);
  const request = updated?.profile.verification.current;
  if (!request) throw new Error("Verification request was not persisted");
  return { submittedAt: request.submittedAt };
}

useSeoMeta({
  title: "Complete seu perfil profissional",
  robots: "noindex, nofollow",
});
</script>

<template>
  <OnboardingWizard
    :services="services"
    :workspace="professionalWorkspace"
    :save-identity="saveOnboardingIdentity"
    :save-supply="saveOnboardingSupply"
    :save-verification="saveOnboardingVerification"
    :upload-photo="uploadPhoto"
    :retry-photo="retryPhoto"
    :photo-uploading="photoUploading"
    :photo-error="photoError"
    :submission-saving="submissionSaving"
    :submission-error="submissionError"
    :submit-profile="submitProfile"
  />
</template>
