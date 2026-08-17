import {
  fetchProfessionalWorkspace,
  attachProfessionalProfilePhoto,
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
import type { Neighborhood, ProfessionalProfileDraft, Service } from "~/types";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";

export async function useProfessionalWorkspace() {
  const client = useApiClient();
  const workspace = await useAsyncData("professional-workspace", () =>
    fetchProfessionalWorkspace(client),
  );
  const photoUploading = shallowRef(false);
  const photoError = shallowRef("");

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

  return {
    ...workspace,
    saveIdentity,
    saveSupply,
    saveProfile,
    photoUploading,
    photoError,
    uploadPhoto,
    retryPhoto,
  };
}
