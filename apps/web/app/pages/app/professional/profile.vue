<script setup lang="ts">
import { computed } from "vue";
import type {
  Professional,
  ProfessionalProfileDraft,
  VerificationSubmission,
} from "~/types";
import { useCatalogs } from "~/composables/useCatalogs";
import { useApplicationSession } from "~/composables/useApplicationSession";
import { useToast } from "~/composables/useToast";
import { ApiRequestError } from "~/services/api/errors";
import type { ProfessionalRelationshipResponse } from "~/services/api/professional-relationships";

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
const neighborhoods = computed(() =>
  (catalog.value?.neighborhoods ?? []).filter((item) => item.code !== "all"),
);
const {
  data: workspace,
  error: workspaceError,
  saveProfile: saveWorkspaceProfile,
  photoUploading,
  photoError,
  uploadPhoto,
  retryPhoto,
  portfolioSaving,
  createPortfolioItem,
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
    avatar: profile.photo.publishedImageUrl ?? "",
    primaryService: primary?.name ?? "",
    primaryServiceSlug:
      services.value.find((service) => service.id === primary?.id)?.slug ?? "",
    services: profile.services.map((service) => service.name),
    serviceNotes: profile.services.map((service) => service.note),
    neighborhoods: profile.coverage.neighborhoods.map(
      (neighborhood) => neighborhood.name,
    ),
    allJoinville: profile.coverage.allJoinville,
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
  pending_review: "Em análise",
  published: "Publicado",
  suspended: "Suspenso",
} as const;
const statusLabel = computed(() => {
  const profile = workspace.value!.profile;
  if (profile.isPublic && profile.revisionStatus === "pending_review") {
    return "Publicado · revisão pendente";
  }
  if (profile.isPublic) return "Publicado";
  if (profile.revisionStatus === "rejected") {
    return "Indisponível após revisão";
  }
  return statusLabels[profile.status];
});
const tabs = [
  { id: "dados", label: "Dados do perfil", icon: "i-lucide-user-round" },
  { id: "portfolio", label: "Portfólio", icon: "i-lucide-images" },
  { id: "relacoes", label: "Minha rede", icon: "i-lucide-handshake" },
  { id: "verificacoes", label: "Verificações", icon: "i-lucide-shield-check" },
];
const activeTab = computed(() =>
  tabs.some((tab) => tab.id === route.query.tab)
    ? String(route.query.tab)
    : "dados",
);

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Editar perfil profissional",
  robots: "noindex, nofollow",
});

async function selectTab(id: string) {
  await router.replace({ query: id === "dados" ? {} : { tab: id } });
}

async function saveProfile(
  draft: ProfessionalProfileDraft,
  confirm: () => void,
) {
  if (saving.value) return;

  saving.value = true;
  try {
    await saveWorkspaceProfile(draft, services.value, neighborhoods.value);
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
      description: "A nova foto já está no perfil e seguirá para revisão.",
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
      description: "A nova foto já está no perfil e seguirá para revisão.",
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

async function handlePortfolioAdd(
  draft: Parameters<typeof createPortfolioItem>[0],
) {
  try {
    await createPortfolioItem(draft);
    showToast({
      title: "Trabalho enviado",
      description: "O trabalho já está no perfil e seguirá para revisão.",
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

async function handlePortfolioRemove(id: string) {
  try {
    await deletePortfolioItem(id);
    showToast({
      title: "Trabalho excluído",
      description: "Ele foi removido do seu portfólio.",
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
              <small v-if="workspace?.profile.revisionRejectionReason">
                {{ workspace?.profile.revisionRejectionReason }}
              </small>
            </span>
          </span>
        </div>
      </DesignSystemContainer>
    </section>
    <DesignSystemContainer class="profile-workspace__content">
      <nav class="workspace-tabs" aria-label="Seções do perfil">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          type="button"
          :class="{ active: activeTab === tab.id }"
          @click="selectTab(tab.id)"
        >
          <UIcon :name="tab.icon" />{{ tab.label
          }}<span
            v-if="tab.id === 'portfolio' || tab.id === 'relacoes'"
            class="workspace-tabs__count"
            >{{
              tab.id === "portfolio"
                ? (workspace?.profile.portfolioItems.length ?? 0)
                : (workspace?.relationships.length ?? 0)
            }}</span
          >
        </button>
      </nav>
      <DashboardProfileEditor
        v-if="activeTab === 'dados'"
        :professional="professional"
        :services="services"
        :neighborhoods="neighborhoods"
        :saving="saving"
        :photo="workspace?.profile.photo"
        :photo-uploading="photoUploading"
        :photo-error="photoError"
        @save="saveProfile"
        @photo-select="handlePhoto"
        @photo-retry="handlePhotoRetry"
      />
      <DashboardPortfolioManager
        v-else-if="activeTab === 'portfolio'"
        :items="workspace?.profile.portfolioItems ?? []"
        :service-options="professional.services"
        :submitting="portfolioSaving"
        @added="handlePortfolioAdd"
        @removed="handlePortfolioRemove"
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
    </DesignSystemContainer>
    <RelationshipCreateDialog
      v-model:open="relationshipOpen"
      :services="services"
      :neighborhoods="neighborhoods"
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
}
.workspace-tabs {
  position: sticky;
  top: 20px;
  align-self: start;
  display: grid;
  gap: 4px;
  & button {
    display: flex;
    align-items: center;
    gap: 8px;
    width: 100%;
    padding: 11px 12px;
    border: 0;
    border-radius: 10px;
    background: transparent;
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 800;
    text-align: left;
    cursor: pointer;
  }
  & button.active {
    background: white;
    color: var(--color-brand);
    box-shadow: 0 5px 15px rgb(23 53 47 / 6%);
  }
  &__count {
    margin-left: auto;
    padding: 3px 6px;
    border-radius: 6px;
    background: var(--paper-strong);
    font-size: 0.82rem;
  }
}
@media (width <= 760px) {
  .profile-workspace {
    &__content {
      grid-template-columns: 1fr;
    }
  }
  .workspace-tabs {
    position: static;
    display: flex;
    overflow-x: auto;
  }
  .workspace-tabs button {
    width: auto;
    white-space: nowrap;
  }
  .workspace-heading {
    &__status > span {
      display: none;
    }
  }
}
</style>
