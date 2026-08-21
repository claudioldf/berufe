import {
  fetchProfessionalWorkspace,
  attachProfessionalProfilePhoto,
  attachProfessionalPortfolioItem,
  deleteProfessionalPortfolioItem,
  deleteProfessionalRelationship,
  attachProfessionalVerificationRequest,
  submitProfessionalProfile,
  updateProfessionalIdentity,
  updateProfessionalProfile,
  updateProfessionalSupply,
} from "~/services/api/professional-workspace";
import {
  retryMediaUpload,
  uploadMedia,
  waitForMediaUpload,
  type MediaUpload,
} from "~/services/api/media-upload";
import type {
  Neighborhood,
  PortfolioItemDraft,
  ProfessionalProfileDraft,
  ProfessionalRelationship,
  Service,
} from "~/types";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  respondProfessionalRelationship,
  type ProfessionalRelationshipResponse,
} from "~/services/api/professional-relationships";

export async function useProfessionalWorkspace() {
  const client = useApiClient();
  const workspace = await useAsyncData("professional-workspace", () =>
    fetchProfessionalWorkspace(client),
  );
  const photoUploading = shallowRef(false);
  const photoError = shallowRef("");
  const portfolioSaving = shallowRef(false);
  const portfolioError = shallowRef("");
  const verificationSaving = shallowRef(false);
  const verificationError = shallowRef("");
  const submissionSaving = shallowRef(false);
  const submissionError = shallowRef("");
  const relationshipRespondingId = shallowRef<string | null>(null);
  const relationshipRemovingId = shallowRef<string | null>(null);
  const relationshipError = shallowRef("");

  function invalidatePublicRelationshipProfiles(
    relationship: ProfessionalRelationship,
  ) {
    clearNuxtData(
      `public-professional-profile-${relationship.initiator.publicSlug}`,
    );
    clearNuxtData(
      `public-professional-profile-${relationship.recipient.publicSlug}`,
    );
  }

  function reflectPhotoUpload(upload: MediaUpload) {
    if (!workspace.data.value) return;
    workspace.data.value.profile.photo.latestUpload = {
      id: upload.id,
      state: upload.state,
      failureCode: upload.failure_code,
      retryable: upload.retryable,
    };
  }

  function failedPhotoError(upload: MediaUpload) {
    return new ApiRequestError({
      code: upload.failure_code ?? "media_processing_failed",
      message: upload.retryable
        ? "Não foi possível processar a foto. Tente novamente."
        : "Essa foto não pôde ser processada. Selecione outra imagem.",
      fieldErrors: {},
      requestId: "profile-photo",
    });
  }

  function failedMediaError(upload: MediaUpload, noun: string) {
    return new ApiRequestError({
      code: upload.failure_code ?? "media_processing_failed",
      message: upload.retryable
        ? `Não foi possível processar ${noun}. Tente novamente.`
        : `${noun} não pôde ser processada. Selecione outra imagem.`,
      fieldErrors: {},
      requestId: "professional-media",
    });
  }

  async function processedMedia(initial: MediaUpload, noun: string) {
    const processed = await waitForMediaUpload(client, initial);
    if (processed.state !== "processed")
      throw failedMediaError(processed, noun);
    return processed;
  }

  async function finishPhotoUpload(initial: MediaUpload) {
    const processed = await waitForMediaUpload(client, initial, {
      onUpdate: reflectPhotoUpload,
    });
    if (processed.state !== "processed") throw failedPhotoError(processed);

    const updated = await attachProfessionalProfilePhoto(client, processed.id);
    workspace.data.value = updated;
    return updated;
  }

  async function runPhotoAction(action: () => Promise<MediaUpload>) {
    if (photoUploading.value) return workspace.data.value;
    photoUploading.value = true;
    photoError.value = "";
    try {
      return await finishPhotoUpload(await action());
    } catch (error) {
      photoError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível enviar a foto. Tente novamente.";
      throw error;
    } finally {
      photoUploading.value = false;
    }
  }

  async function uploadPhoto(file: File) {
    return runPhotoAction(() => uploadMedia(client, file, "profile_photo"));
  }

  async function retryPhoto() {
    const upload = workspace.data.value?.profile.photo.latestUpload;
    if (!upload?.retryable) return workspace.data.value;
    return runPhotoAction(() => retryMediaUpload(client, upload.id));
  }

  async function createPortfolioItem(draft: PortfolioItemDraft) {
    if (portfolioSaving.value) return workspace.data.value;
    const service = workspace.data.value?.profile.services.find(
      (selection) => selection.name === draft.service,
    );
    if (!service) {
      throw new ApiRequestError({
        code: "service_not_selected",
        message: "Selecione um serviço ativo do seu perfil.",
        fieldErrors: {},
        requestId: "portfolio-item",
      });
    }

    portfolioSaving.value = true;
    portfolioError.value = "";
    try {
      const upload = await uploadMedia(client, draft.file, "portfolio_image");
      const processed = await processedMedia(upload, "a imagem");
      const updated = await attachProfessionalPortfolioItem(client, {
        mediaUploadId: processed.id,
        serviceId: service.id,
        title: draft.title,
        description: draft.description,
      });
      workspace.data.value = updated;
      return updated;
    } catch (error) {
      portfolioError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível enviar o trabalho. Tente novamente.";
      throw error;
    } finally {
      portfolioSaving.value = false;
    }
  }

  async function deletePortfolioItem(id: string) {
    portfolioError.value = "";
    try {
      const updated = await deleteProfessionalPortfolioItem(client, id);
      workspace.data.value = updated;
      return updated;
    } catch (error) {
      portfolioError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível excluir o trabalho. Tente novamente.";
      throw error;
    }
  }

  async function createVerificationRequest(file: File) {
    if (verificationSaving.value) return workspace.data.value;
    verificationSaving.value = true;
    verificationError.value = "";
    try {
      const upload = await uploadMedia(client, file, "verification_identity");
      const processed = await processedMedia(upload, "a imagem");
      const updated = await attachProfessionalVerificationRequest(
        client,
        processed.id,
      );
      workspace.data.value = updated;
      return updated;
    } catch (error) {
      verificationError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível enviar a evidência. Tente novamente.";
      throw error;
    } finally {
      verificationSaving.value = false;
    }
  }

  async function saveIdentity(draft: ProfessionalProfileDraft) {
    const updated = await updateProfessionalIdentity(client, draft);
    workspace.data.value = updated;
    return updated;
  }

  async function saveSupply(
    draft: ProfessionalProfileDraft,
    services: Service[],
    neighborhoods: Neighborhood[],
  ) {
    const updated = await updateProfessionalSupply(
      client,
      draft,
      services,
      neighborhoods,
    );
    workspace.data.value = updated;
    return updated;
  }

  async function saveProfile(
    draft: ProfessionalProfileDraft,
    services: Service[],
    neighborhoods: Neighborhood[],
  ) {
    const updated = await updateProfessionalProfile(
      client,
      draft,
      services,
      neighborhoods,
    );
    workspace.data.value = updated;
    return updated;
  }

  async function submitProfile() {
    if (submissionSaving.value) return workspace.data.value;
    submissionSaving.value = true;
    submissionError.value = "";
    try {
      const updated = await submitProfessionalProfile(client);
      workspace.data.value = updated;
      return updated;
    } catch (error) {
      if (error instanceof ApiRequestError) {
        submissionError.value =
          Object.values(error.fieldErrors).flat()[0] ?? error.message;
      } else {
        submissionError.value =
          "Não foi possível enviar o perfil agora. Tente novamente.";
      }
      throw error;
    } finally {
      submissionSaving.value = false;
    }
  }

  async function respondToRelationship(
    id: string,
    response: ProfessionalRelationshipResponse,
  ) {
    if (relationshipRespondingId.value || relationshipRemovingId.value)
      return undefined;

    relationshipRespondingId.value = id;
    relationshipError.value = "";
    try {
      const relationship = await respondProfessionalRelationship(
        client,
        id,
        response,
      );
      if (workspace.data.value) {
        workspace.data.value.pendingRelationships =
          workspace.data.value.pendingRelationships.filter(
            (pending) => pending.id !== id,
          );
        workspace.data.value.relationships =
          relationship.status === "accepted"
            ? workspace.data.value.relationships.map((current) =>
                current.id === id ? relationship : current,
              )
            : workspace.data.value.relationships.filter(
                (current) => current.id !== id,
              );
      }
      invalidatePublicRelationshipProfiles(relationship);
      return relationship;
    } catch (error) {
      relationshipError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível responder à solicitação de conexão agora. Tente novamente.";
      throw error;
    } finally {
      relationshipRespondingId.value = null;
    }
  }

  async function removeRelationship(id: string) {
    if (relationshipRespondingId.value || relationshipRemovingId.value)
      return workspace.data.value;

    relationshipRemovingId.value = id;
    relationshipError.value = "";
    const relationship = workspace.data.value?.relationships.find(
      (current) => current.id === id,
    );
    try {
      const updated = await deleteProfessionalRelationship(client, id);
      workspace.data.value = updated;
      if (relationship) invalidatePublicRelationshipProfiles(relationship);
      return updated;
    } catch (error) {
      relationshipError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível remover a conexão agora. Tente novamente.";
      throw error;
    } finally {
      relationshipRemovingId.value = null;
    }
  }

  return {
    ...workspace,
    saveIdentity,
    saveSupply,
    saveProfile,
    photoUploading,
    photoError,
    uploadPhoto,
    retryPhoto,
    portfolioSaving,
    portfolioError,
    createPortfolioItem,
    deletePortfolioItem,
    verificationSaving,
    verificationError,
    createVerificationRequest,
    submissionSaving,
    submissionError,
    submitProfile,
    relationshipRespondingId,
    relationshipRemovingId,
    relationshipError,
    respondToRelationship,
    removeRelationship,
  };
}
