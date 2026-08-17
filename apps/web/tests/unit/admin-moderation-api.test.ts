import type { BerufeApiClient } from "@app/services/api/client";
import {
  createAdminModerationDecision,
  fetchAdminModeration,
  fetchAdminModerationMedia,
  fetchAdminVerificationFile,
  formatModerationAge,
  mapAdminModeration,
} from "@app/services/api/admin-moderation";
import type { components } from "@app/services/api/schema";
import type { ModerationFilters } from "@app/types";

type AdminModerationData = components["schemas"]["AdminModerationData"];

const data: AdminModerationData = {
  items: [
    {
      target_type: "profile_photo",
      target_id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
      status: "pending_review",
      title: "Foto de perfil · Ana Souza",
      subtitle: "Eletricista · Toda Joinville",
      submitted_at: "2026-08-17T12:00:00Z",
      details: "Foto enviada para conferência manual.",
      preview: "Imagem privada",
      has_media: true,
      verification_file_id: null,
    },
  ],
  meta: { page: 1, per_page: 20, total_count: 1, total_pages: 1 },
  summary: {
    pending_count: 1,
    reviewed_today_count: 3,
    oldest_pending_submitted_at: "2026-08-17T12:00:00Z",
  },
};

const filters: ModerationFilters = {
  type: "all",
  status: "pending_review",
  search: "Ana",
  page: 1,
  perPage: 20,
};

function clientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
    POST: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

const successfulQueue = () => ({
  data: { data, request_id: "moderation-200" },
  error: undefined,
  response: new Response(null),
});

describe("administrator moderation API", () => {
  it("maps the safe queue, summary, presentation labels, and relative ages", () => {
    const mapped = mapAdminModeration(data, new Date("2026-08-17T15:30:00Z"));

    expect(mapped.items[0]).toMatchObject({
      id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
      targetType: "profile_photo",
      type: "Foto",
      age: "há 3h",
      hasMedia: true,
    });
    expect(mapped.summary).toMatchObject({
      pendingCount: 1,
      reviewedTodayCount: 3,
      oldestPendingAge: "há 3h",
    });
    expect(formatModerationAge(null)).toBe("—");
    expect(
      formatModerationAge(
        "2026-08-15T12:00:00Z",
        new Date("2026-08-17T15:30:00Z"),
      ),
    ).toBe("há 2d");
  });

  it("uses the generated queue and decision operations with server filters", async () => {
    const client = clientReturning(successfulQueue());

    await fetchAdminModeration(client, filters);
    await createAdminModerationDecision(
      client,
      "profile_photo",
      "de83e041-286f-4b50-91fa-61a0ee8c1801",
      "rejected",
      filters,
      { reason: "A imagem precisa ser substituída.", note: "Conferida." },
    );

    expect(client.GET).toHaveBeenCalledWith("/api/v1/admin/moderation", {
      params: {
        query: {
          type: "all",
          status: "pending_review",
          search: "Ana",
          page: 1,
          per_page: 20,
        },
      },
    });
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/admin/moderation/{target_type}/{target_id}/decisions",
      {
        params: {
          path: {
            target_type: "profile_photo",
            target_id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
          },
          query: {
            type: "all",
            status: "pending_review",
            search: "Ana",
            page: 1,
            per_page: 20,
          },
        },
        body: {
          decision: {
            action: "rejected",
            reason: "A imagem precisa ser substituída.",
            note: "Conferida.",
          },
        },
      },
    );
  });

  it("requests private media as a Blob and never constructs a storage URL", async () => {
    const blob = new Blob(["image"], { type: "image/jpeg" });
    const client = clientReturning({
      data: blob,
      error: undefined,
      response: new Response(null),
    });

    await expect(
      fetchAdminModerationMedia(
        client,
        "profile_photo",
        "de83e041-286f-4b50-91fa-61a0ee8c1801",
      ),
    ).resolves.toBe(blob);
    expect(client.GET).toHaveBeenCalledWith(
      "/api/v1/admin/moderation/{target_type}/{target_id}/media",
      {
        params: {
          path: {
            target_type: "profile_photo",
            target_id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
          },
        },
        parseAs: "blob",
      },
    );
  });

  it("requests retained identity evidence as an audited Blob response", async () => {
    const blob = new Blob(["identity"], { type: "image/png" });
    const client = clientReturning({
      data: blob,
      error: undefined,
      response: new Response(null),
    });

    await expect(
      fetchAdminVerificationFile(
        client,
        "43a94f5e-1429-4ec7-bbc4-a6f805d5182d",
      ),
    ).resolves.toBe(blob);
    expect(client.GET).toHaveBeenCalledWith(
      "/api/v1/admin/verification-files/{id}/content",
      {
        params: {
          path: { id: "43a94f5e-1429-4ec7-bbc4-a6f805d5182d" },
        },
        parseAs: "blob",
      },
    );
  });

  it("normalizes a missing private queue payload", async () => {
    const client = clientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null, {
        headers: { "X-Request-Id": "moderation-missing" },
      }),
    });

    await expect(fetchAdminModeration(client, filters)).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "unexpected_error",
      requestId: "moderation-missing",
    });
  });
});
