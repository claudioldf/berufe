<script setup lang="ts">
import { computed } from "vue";
import type {
  PortfolioItemUpdateDraft,
  Professional,
  ProfessionalProfileDraft,
  VerificationSubmission,
} from "~/types";
import { useCatalogs } from "~/composables/useCatalogs";
import { useApplicationSession } from "~/composables/useApplicationSession";
import { useToast } from "~/composables/useToast";
import { ApiRequestError } from "~/services/api/errors";
import type { ProfessionalRelationshipResponse } from "~/services/api/professional-relationships";
import { professionalAccountExclusionPath } from "~/utils/professional-auth";

const route = useRoute();
const router = useRouter();
const { showToast } = useToast();
const { account } = useApplicationSession();
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
  saveProfile: saveWorkspaceProfile,
  photoUploading,
  photoRemoving,
  photoError,
  uploadPhoto,
  retryPhoto,
  removePhoto,
  portfolioSaving,
  createPortfolioItem,
  updatePortfolioItem,
  deletePortfolioItem,
  verificationSaving,
  verificationError,
  createVerificationRequest,
  relationshipRespondingId,
  relationshipRemovingId,
  relationshipError,
  respondToRelationship,
  removeRelationship,
} = await useProfessionalWorkspace();
if (workspaceError.value || !workspace.value) {
  throw createError({
    statusCode: 503,
    statusMessage: "Seu perfil está temporariamente indisponível.",
  });
}
const saving = shallowRef(false);
const relationshipOpen = shallowRef(false);
const relationshipEligible = computed(
  () => account.value?.relationshipEligible ?? false,
);
// Every field is derived from the authenticated workspace. Nothing is borrowed
// from a fixture: the editor must only ever show this professional's own data.
const professional = computed<Professional>(() => {
  const profile = workspace.value!.profile;
  const primary =
    profile.services.find((service) => service.isPrimary) ??
    profile.services[0];

  return {
    id: profile.id,
    slug: profile.publicSlug,
    name: profile.identity.name,
    headline: profile.identity.headline,
    bio: profile.identity.bio,
    avatar: profile.photo.imageUrl ?? "",
    primaryService: primary?.name ?? "",
    primaryServiceSlug:
      services.value.find((service) => service.id === primary?.id)?.slug ?? "",
    services: profile.services.map((service) => service.name),
    serviceNotes: profile.services.map((service) => service.note),
    coverage: profile.coverage,
    yearsExperience: profile.identity.yearsExperience,
    evidence: [
      { id: "phone-confirmed", label: "Telefone confirmado" },
      ...(profile.verification.current?.status === "approved"
        ? [{ id: "identity-verified", label: "Identidade verificada" }]
        : []),
    ],
    portfolio: [],
    relationships: [],
    updatedAt: "",
    whatsapp: profile.identity.whatsapp,
    birthdate: profile.identity.birthdate,
    instagram: profile.identity.instagram || undefined,
    youtube: profile.identity.youtube || undefined,
  };
});
const statusLabels = {
  draft: "Rascunho",
  published: "Publicado",
  suspended: "Suspenso",
} as const;
const statusLabel = computed(() => {
  const profile = workspace.value!.profile;
  if (profile.isPublic) return "Publicado";
  if (
    profile.status === "published" &&
    profile.publicationBlockers.includes("photo")
  ) {
    return "Indisponível · adicione uma foto";
  }
  return statusLabels[profile.status];
});
const profileTabIds = ["dados", "portfolio", "relacoes", "verificacoes"];
const activeTab = computed(() =>
  profileTabIds.includes(String(route.query.tab))
    ? String(route.query.tab)
    : "dados",
);
const requestedPortfolioEditId = computed(() => {
  const requested = Array.isArray(route.query.edit)
    ? route.query.edit[0]
    : route.query.edit;
  return typeof requested === "string" && requested ? requested : null;
});

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Editar perfil profissional",
  robots: "noindex, nofollow",
});

async function saveProfile(
  draft: ProfessionalProfileDraft,
  confirm: () => void,
) {
  if (saving.value) return;

  saving.value = true;
  try {
    await saveWorkspaceProfile(draft, services.value);
    confirm();
    showToast({
      title: "Perfil atualizado",
      description: "As alterações foram salvas.",
    });
  } catch (error) {
    showToast({
      title: "Não foi possível salvar",
      description:
        error instanceof ApiRequestError
          ? error.message
          : "Tente novamente em instantes.",
    });
  } finally {
    saving.value = false;
  }
}

async function handlePhoto(file: File) {
  try {
    await uploadPhoto(file);
    showToast({
      title: "Foto enviada",
      description: "A nova foto já está no perfil.",
    });
  } catch (error) {
    showToast({
      title: "Não foi possível enviar a foto",
      description:
        error instanceof ApiRequestError
          ? error.message
          : "Tente novamente em instantes.",
    });
  }
}

async function handlePhotoRetry() {
  try {
    await retryPhoto();
    showToast({
      title: "Foto reenviada",
      description: "A nova foto já está no perfil.",
    });
  } catch (error) {
    showToast({
      title: "Não foi possível reenviar a foto",
      description:
        error instanceof ApiRequestError
          ? error.message
          : "Tente novamente em instantes.",
    });
  }
}

async function handlePhotoRemove() {
  try {
    await removePhoto();
    showToast({
      title: "Foto removida",
      description:
        "Ela não aparece mais no perfil. Adicione outra foto para publicá-lo novamente.",
    });
  } catch (error) {
    showToast({
      title: "Não foi possível remover a foto",
      description:
        error instanceof ApiRequestError
          ? error.message
          : "Tente novamente em instantes.",
    });
  }
}

async function handlePortfolioAdd(
  draft: Parameters<typeof createPortfolioItem>[0],
) {
  try {
    await createPortfolioItem(draft);
    showToast({
      title: "Trabalho enviado",
      description: "O trabalho já está no perfil.",
    });
  } catch (error) {
    showToast({
      title: "Não foi possível enviar o trabalho",
      description:
        error instanceof ApiRequestError
          ? error.message
          : "Tente novamente em instantes.",
    });
  }
}

async function handlePortfolioUpdate(
  id: string,
  draft: PortfolioItemUpdateDraft,
) {
  try {
    await updatePortfolioItem(id, draft);
    showToast({
      title: "Trabalho atualizado",
      description: "As alterações já estão no perfil.",
    });
  } catch (error) {
    showToast({
      title: "Não foi possível reenviar o trabalho",
      description:
        error instanceof ApiRequestError
          ? error.message
          : "Tente novamente em instantes.",
    });
  }
}

async function clearPortfolioEditIntent() {
  if (!route.query.edit) return;
  const query = { ...route.query };
  delete query.edit;
  await router.replace({ path: route.path, query });
}

async function handlePortfolioRemove(id: string) {
  try {
    await deletePortfolioItem(id);
    showToast({
      title: "Trabalho excluído",
      description: "Ele foi removido dos seus trabalhos.",
    });
  } catch (error) {
    showToast({
      title: "Não foi possível excluir o trabalho",
      description:
        error instanceof ApiRequestError
          ? error.message
          : "Tente novamente em instantes.",
    });
  }
}

async function handleVerificationSubmission(
  submission: VerificationSubmission,
) {
  try {
    await createVerificationRequest(submission.file);
    showToast({
      title: "Verificação enviada",
      description: "A equipe Berufe fará a conferência manual.",
    });
  } catch (error) {
    showToast({
      title: "Não foi possível enviar a verificação",
      description:
        error instanceof ApiRequestError
          ? error.message
          : "Tente novamente em instantes.",
    });
  }
}

async function handleRelationshipResponse(
  id: string,
  response: ProfessionalRelationshipResponse,
) {
  try {
    await respondToRelationship(id, response);
    showToast({
      title:
        response === "accepted"
          ? "Vocês estão conectados"
          : "Solicitação de conexão recusada",
      description:
        response === "accepted"
          ? "A conexão já pode aparecer nos perfis públicos."
          : "A solicitação de conexão recusada não aparecerá publicamente.",
    });
  } catch {
    // The relationship manager keeps the normalized API error visible.
  }
}

async function handleRelationshipRemove(id: string) {
  const relationship = workspace.value?.relationships.find(
    (current) => current.id === id,
  );
  const cancelling = relationship?.status === "pending";

  try {
    await removeRelationship(id);
    showToast({
      title: cancelling
        ? "Solicitação de conexão cancelada"
        : "Conexão removida",
      description: cancelling
        ? "Você poderá enviar uma nova solicitação de conexão no futuro."
        : "A conexão não aparece mais nos perfis públicos.",
    });
  } catch {
    // The relationship manager keeps the normalized API error visible.
  }
}
</script>

<template>
  <div class="profile-workspace">
    <section class="workspace-heading">
      <DesignSystemContainer class="workspace-heading__inner">
        <div>
          <NuxtLink to="/app/professional"
            ><UIcon name="i-lucide-arrow-left" /> Painel</NuxtLink
          >
          <h1>Meu perfil</h1>
          <p>Organize as informações e evidências que clientes verão.</p>
        </div>
        <div class="workspace-heading__status">
          <span>
            <DesignSystemStatusDot tone="success" />
            <span>
              {{ statusLabel }}
            </span>
          </span>
        </div>
      </DesignSystemContainer>
    </section>
    <DesignSystemContainer class="profile-workspace__content">
      <DashboardProfessionalWorkspaceTabs
        :portfolio-count="workspace?.profile.portfolioItems.length ?? 0"
        :relationship-count="workspace?.relationships.length ?? 0"
      />
      <div class="profile-workspace__panel">
        <DashboardProfileEditor
          v-if="activeTab === 'dados'"
          :professional="professional"
          :services="services"
          :saving="saving"
          :photo="workspace?.profile.photo"
          :photo-uploading="photoUploading"
          :photo-removing="photoRemoving"
          :photo-error="photoError"
          @save="saveProfile"
          @photo-select="handlePhoto"
          @photo-retry="handlePhotoRetry"
          @photo-remove="handlePhotoRemove"
        />
        <DashboardPortfolioManager
          v-else-if="activeTab === 'portfolio'"
          :items="workspace?.profile.portfolioItems ?? []"
          :service-options="professional.services"
          :submitting="portfolioSaving"
          :initial-edit-item-id="requestedPortfolioEditId"
          @added="handlePortfolioAdd"
          @updated="handlePortfolioUpdate"
          @removed="handlePortfolioRemove"
          @edit-closed="clearPortfolioEditIntent"
        />
        <DashboardRelationshipManager
          v-else-if="activeTab === 'relacoes'"
          :relationships="workspace?.relationships ?? []"
          :owner-id="workspace?.profile.id ?? ''"
          :responding-id="relationshipRespondingId"
          :removing-id="relationshipRemovingId"
          :error="relationshipError"
          @add="relationshipOpen = true"
          @respond="handleRelationshipResponse"
          @remove="handleRelationshipRemove"
        />
        <DashboardVerificationPanel
          v-else
          :evidence="professional.evidence"
          :verification="workspace?.profile.verification ?? { current: null }"
          :submitting="verificationSaving"
          :server-error="verificationError"
          @submitted="handleVerificationSubmission"
        />
        <div v-if="activeTab === 'dados'" class="profile-workspace__account">
          <NuxtLink :to="professionalAccountExclusionPath">
            Excluir minha conta <UIcon name="i-lucide-arrow-right" />
          </NuxtLink>
        </div>
      </div>
    </DesignSystemContainer>
    <RelationshipCreateDialog
      v-model:open="relationshipOpen"
      :services="services"
      :eligible="relationshipEligible"
    />
  </div>
</template>

<style scoped lang="scss">
.profile-workspace {
  min-height: 100vh;
  padding-bottom: 80px;
  background: var(--color-surface-canvas);
}
.workspace-heading {
  padding: 34px 0 38px;
  background: var(--color-brand-strong);
  color: white;
  &__inner {
    display: flex;
    justify-content: space-between;
    align-items: end;
  }
  & a {
    display: flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 20px;
    color: rgb(255 255 255 / 58%);
    font-size: 0.86rem;
    font-weight: 700;
    text-decoration: none;
  }
  & h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2.7rem;
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  & p {
    margin: 7px 0 0;
    color: rgb(255 255 255 / 59%);
    font-size: 0.84rem;
  }
  &__status {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  &__status > span {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 7px 10px;
    border: 1px solid rgb(255 255 255 / 16%);
    border-radius: 9px;
    color: #b7dfd3;
    font-size: 0.84rem;
    font-weight: 850;
  }
  &__status > span span,
  &__status > span small {
    display: block;
  }
  &__status > span small {
    max-width: 320px;
    margin-top: 2px;
    color: rgb(255 255 255 / 72%);
    font-size: 0.72rem;
    font-weight: 600;
  }
}
.profile-workspace {
  &__content {
    display: grid;
    grid-template-columns: 190px minmax(0, 1fr);
    gap: 28px;
    padding-top: 26px;
  }

  &__panel {
    min-width: 0;
  }

  &__account {
    margin-top: 14px;
    padding-inline: 26px;
  }

  &__account a {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    color: var(--ui-error);
    font-size: 0.86rem;
    font-weight: 700;
    text-decoration: none;
  }

  &__account a:hover {
    color: color-mix(in srgb, var(--ui-error) 80%, black);
  }
}
@media (width <= 760px) {
  .profile-workspace {
    &__content {
      grid-template-columns: 1fr;
    }
  }
  .workspace-heading {
    &__status > span {
      display: none;
    }
  }
}
</style>
