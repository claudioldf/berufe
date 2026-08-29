import type { BerufeApiClient } from "~/services/api/client";
import {
  getDataErasureRequestStatus,
  requestProfessionalDataErasure,
} from "~/services/api/professional-data-erasure";

const contractedRequest = {
  reference: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
  status: "requested" as const,
  requested_at: "2026-08-29T15:00:00.000Z",
  unpublished_at: "2026-08-29T15:00:00.000Z",
  completion_deadline_at: "2026-09-28T15:00:00.000Z",
  completed_at: null,
};

function apiClientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
    POST: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("professional data erasure API", () => {
  it("submits only the explicit confirmation and maps the privacy-safe status", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          status_token: "be_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ",
          request: contractedRequest,
        },
        request_id: "erasure-submit",
      },
      error: undefined,
      response: new Response(null, { status: 202 }),
    });

    await expect(
      requestProfessionalDataErasure(client, "EXCLUIR"),
    ).resolves.toEqual({
      statusToken: "be_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ",
      request: {
        reference: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
        status: "requested",
        requestedAt: "2026-08-29T15:00:00.000Z",
        unpublishedAt: "2026-08-29T15:00:00.000Z",
        completionDeadlineAt: "2026-09-28T15:00:00.000Z",
        completedAt: null,
      },
    });
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/data-erasure-request",
      { body: { confirmation: "EXCLUIR" } },
    );
  });

  it("looks up status by opaque token without sending account identifiers", async () => {
    const client = apiClientReturning({
      data: { data: { ...contractedRequest, status: "completed" } },
      error: undefined,
      response: new Response(null, { status: 200 }),
    });

    await expect(
      getDataErasureRequestStatus(client, "be_status-token"),
    ).resolves.toMatchObject({ status: "completed" });
    expect(client.GET).toHaveBeenCalledWith(
      "/api/v1/data-erasure-requests/{status_token}",
      { params: { path: { status_token: "be_status-token" } } },
    );
  });

  it("normalizes submission and status lookup failures", async () => {
    const result = {
      data: undefined,
      error: {
        error: {
          code: "recent_verification_required",
          message: "Confirme seu telefone por SMS novamente para continuar.",
          request_id: "erasure-428",
        },
      },
      response: new Response(null, {
        status: 428,
        headers: { "X-Request-Id": "erasure-428" },
      }),
    };
    const client = apiClientReturning(result);

    await expect(
      requestProfessionalDataErasure(client, "EXCLUIR"),
    ).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "recent_verification_required",
      requestId: "erasure-428",
    });
    await expect(
      getDataErasureRequestStatus(client, "be_status-token"),
    ).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "recent_verification_required",
    });
  });
});
