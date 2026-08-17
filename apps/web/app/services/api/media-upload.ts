import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";

export type MediaUploadPurpose =
  components["schemas"]["MediaUploadAuthorizationRequest"]["purpose"];
export type MediaUpload = components["schemas"]["MediaUpload"];

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

export async function authorizeMediaUpload(
  client: BerufeApiClient,
  file: File,
  purpose: MediaUploadPurpose,
) {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/media-uploads",
    {
      body: {
        purpose,
        content_type: file.type as "image/jpeg" | "image/png",
        byte_size: file.size,
      },
    },
  );
  if (error || !data) throw requestError(error, response);

  return data.data;
}

export async function completeMediaUpload(
  client: BerufeApiClient,
  id: string,
): Promise<MediaUpload> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/media-uploads/{id}/completion",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);

  return data.data.media_upload;
}

export async function fetchMediaUpload(
  client: BerufeApiClient,
  id: string,
): Promise<MediaUpload> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/media-uploads/{id}",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);

  return data.data.media_upload;
}

export async function retryMediaUpload(
  client: BerufeApiClient,
  id: string,
): Promise<MediaUpload> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/media-uploads/{id}/retry",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);

  return data.data.media_upload;
}

export async function uploadMedia(
  client: BerufeApiClient,
  file: File,
  purpose: MediaUploadPurpose,
  fetcher: typeof globalThis.fetch = globalThis.fetch,
): Promise<MediaUpload> {
  const authorization = await authorizeMediaUpload(client, file, purpose);
  const uploadResponse = await fetcher(authorization.upload.url, {
    method: authorization.upload.method,
    headers: authorization.upload.headers,
    body: file,
    credentials: authorization.upload.strategy === "rails" ? "include" : "omit",
  });
  if (!uploadResponse.ok) {
    throw new ApiRequestError({
      code: "media_upload_failed",
      message: "Não foi possível enviar a imagem. Tente novamente.",
      fieldErrors: {},
      requestId: uploadResponse.headers.get("X-Request-Id") ?? "media-upload",
    });
  }

  return completeMediaUpload(client, authorization.media_upload.id);
}
