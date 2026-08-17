import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchMediaUpload,
  retryMediaUpload,
  uploadMedia,
} from "@app/services/api/media-upload";
import type { components } from "@app/services/api/schema";

type MediaUpload = components["schemas"]["MediaUpload"];

const mediaUpload: MediaUpload = {
  id: "12d12a91-582e-4f1b-aa6b-49b5fd7ce1eb",
  purpose: "profile_photo",
  state: "uploaded",
  declared_content_type: "image/jpeg",
  declared_byte_size: 3,
  actual_content_type: null,
  actual_byte_size: null,
  width: null,
  height: null,
  failure_code: null,
  retryable: false,
  authorization_expires_at: "2026-08-17T12:10:00Z",
};

function response(data: unknown) {
  return {
    data,
    error: undefined,
    response: new Response(null),
  };
}

describe("professional media upload API", () => {
  it("uploads bytes to Rails with credentials and then completes processing", async () => {
    const client = {
      POST: vi
        .fn()
        .mockResolvedValueOnce(
          response({
            data: {
              media_upload: mediaUpload,
              upload: {
                strategy: "rails",
                method: "PUT",
                url: "http://localhost:3001/api/v1/professional/media-uploads/12d12a91-582e-4f1b-aa6b-49b5fd7ce1eb/content",
                headers: { "Content-Type": "image/jpeg" },
              },
            },
            request_id: "authorize",
          }),
        )
        .mockResolvedValueOnce(
          response({
            data: { media_upload: mediaUpload },
            request_id: "complete",
          }),
        ),
    } as unknown as BerufeApiClient;
    const fetcher = vi
      .fn()
      .mockResolvedValue(new Response(null, { status: 200 }));
    const file = new File(["jpg"], "ignored-name.jpg", { type: "image/jpeg" });

    await expect(
      uploadMedia(client, file, "profile_photo", fetcher),
    ).resolves.toEqual(mediaUpload);
    expect(client.POST).toHaveBeenNthCalledWith(
      1,
      "/api/v1/professional/media-uploads",
      {
        body: {
          purpose: "profile_photo",
          content_type: "image/jpeg",
          byte_size: 3,
        },
      },
    );
    expect(fetcher).toHaveBeenCalledWith(expect.stringContaining("/content"), {
      method: "PUT",
      headers: { "Content-Type": "image/jpeg" },
      body: file,
      credentials: "include",
    });
    expect(client.POST).toHaveBeenNthCalledWith(
      2,
      "/api/v1/professional/media-uploads/{id}/completion",
      { params: { path: { id: mediaUpload.id } } },
    );
  });

  it("omits credentials for a direct object-store upload", async () => {
    const client = {
      POST: vi
        .fn()
        .mockResolvedValueOnce(
          response({
            data: {
              media_upload: mediaUpload,
              upload: {
                strategy: "direct",
                method: "PUT",
                url: "https://private.example/signed",
                headers: { "Content-Type": "image/jpeg" },
              },
            },
            request_id: "authorize",
          }),
        )
        .mockResolvedValueOnce(
          response({
            data: { media_upload: mediaUpload },
            request_id: "complete",
          }),
        ),
    } as unknown as BerufeApiClient;
    const fetcher = vi
      .fn()
      .mockResolvedValue(new Response(null, { status: 200 }));

    await uploadMedia(
      client,
      new File(["png"], "image.png", { type: "image/png" }),
      "portfolio_image",
      fetcher,
    );

    expect(fetcher).toHaveBeenCalledWith(
      "https://private.example/signed",
      expect.objectContaining({ credentials: "omit" }),
    );
  });

  it("reads status, retries transient failures, and preserves safe API errors", async () => {
    const client = {
      GET: vi.fn().mockResolvedValue(
        response({
          data: { media_upload: mediaUpload },
          request_id: "show",
        }),
      ),
      POST: vi.fn().mockResolvedValue({
        data: undefined,
        error: {
          error: {
            code: "upload_not_retryable",
            message: "Selecione a imagem novamente.",
            request_id: "retry",
          },
        },
        response: new Response(null, { status: 409 }),
      }),
    } as unknown as BerufeApiClient;

    await expect(fetchMediaUpload(client, mediaUpload.id)).resolves.toEqual(
      mediaUpload,
    );
    await expect(
      retryMediaUpload(client, mediaUpload.id),
    ).rejects.toMatchObject({
      code: "upload_not_retryable",
      requestId: "retry",
    });
  });
});
