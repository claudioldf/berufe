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
const neighborhoods = computed(() =>
  (catalog.value?.neighborhoods ?? []).filter((item) => item.code !== "all"),
);
const {
  data: workspace,
  error: workspaceError,
  saveIdentity,
  saveSupply,
  photoUploading,
  photoError,
  uploadPhoto,
  retryPhoto,
  createPortfolioItem,
  createVerificationRequest,
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
  const updated = await saveSupply(draft, services.value, neighborhoods.value);
  const selections = updated.profile.services;
  return {
    ...draft,
    selectedServices: selections.map((selection) => selection.name),
    primaryService:
      selections.find((selection) => selection.isPrimary)?.name ?? "",
    serviceNotes: Object.fromEntries(
      selections.map((selection) => [selection.name, selection.note]),
    ),
    allJoinville: updated.profile.coverage.allJoinville,
    selectedNeighborhoods: updated.profile.coverage.neighborhoods.map(
      (neighborhood) => neighborhood.name,
    ),
  };
}

async function saveOnboardingPortfolio(
  draft: Parameters<typeof createPortfolioItem>[0],
) {
  const updated = await createPortfolioItem(draft);
  const item = updated?.profile.portfolioItems[0];
  if (!item) throw new Error("Portfolio item was not persisted");
  return {
    title: item.title,
    service: item.service,
    description: item.description,
    submittedAt: item.submittedAt,
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
    :neighborhoods="neighborhoods"
    :workspace="professionalWorkspace"
    :save-identity="saveOnboardingIdentity"
    :save-supply="saveOnboardingSupply"
    :save-portfolio="saveOnboardingPortfolio"
    :save-verification="saveOnboardingVerification"
    :upload-photo="uploadPhoto"
    :retry-photo="retryPhoto"
    :photo-uploading="photoUploading"
    :photo-error="photoError"
  />
</template>
