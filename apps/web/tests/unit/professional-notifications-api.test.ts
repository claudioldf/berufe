import type { BerufeApiClient } from "@app/services/api/client";
import {
  getProfessionalNotifications,
  readAllProfessionalNotifications,
  readProfessionalNotification,
} from "@app/services/api/professional-notifications";

function apiClientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
    PATCH: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

const contractNotification = {
  id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
  notification_type: "quote_approved" as const,
  status: "unread" as const,
  title: "Orçamento aprovado",
  description: "Um cliente aprovou um orçamento.",
  route: "/app/professional/quotes/new?quote=quote-id",
  occurred_at: "2026-08-30T12:00:00Z",
  read_at: null,
};

describe("professional notifications API", () => {
  it("maps a cursor page without exposing contract casing", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          notifications: [contractNotification],
          unread_count: 3,
          next_cursor: "signed-cursor",
        },
        request_id: "notifications-index",
      },
      error: undefined,
      response: new Response(null, { status: 200 }),
    });

    await expect(
      getProfessionalNotifications(client, { cursor: "before", limit: 20 }),
    ).resolves.toEqual({
      notifications: [
        {
          id: contractNotification.id,
          notificationType: "quote_approved",
          status: "unread",
          title: "Orçamento aprovado",
          description: "Um cliente aprovou um orçamento.",
          route: "/app/professional/quotes/new?quote=quote-id",
          occurredAt: "2026-08-30T12:00:00Z",
          readAt: null,
        },
      ],
      unreadCount: 3,
      nextCursor: "signed-cursor",
    });
    expect(client.GET).toHaveBeenCalledWith(
      "/api/v1/professional/notifications",
      { params: { query: { cursor: "before", limit: 20 } } },
    );
  });

  it("marks one notification and all current notifications through typed mutations", async () => {
    const oneClient = apiClientReturning({
      data: {
        data: {
          notification: {
            ...contractNotification,
            status: "read",
            read_at: "2026-08-30T12:05:00Z",
          },
          unread_count: 2,
        },
        request_id: "notification-read",
      },
      error: undefined,
      response: new Response(null, { status: 200 }),
    });
    await expect(
      readProfessionalNotification(oneClient, contractNotification.id),
    ).resolves.toMatchObject({
      notification: { status: "read" },
      unreadCount: 2,
    });
    expect(oneClient.PATCH).toHaveBeenCalledWith(
      "/api/v1/professional/notifications/{id}/read",
      { params: { path: { id: contractNotification.id } } },
    );

    const allClient = apiClientReturning({
      data: {
        data: { marked_read_count: 2, unread_count: 1 },
        request_id: "notifications-read-all",
      },
      error: undefined,
      response: new Response(null, { status: 200 }),
    });
    await expect(readAllProfessionalNotifications(allClient)).resolves.toEqual({
      markedReadCount: 2,
      unreadCount: 1,
    });
    expect(allClient.PATCH).toHaveBeenCalledWith(
      "/api/v1/professional/notifications/read-all",
    );
  });

  it("normalizes server errors", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "forbidden",
          message: "Acesso negado.",
          request_id: "notifications-denied",
        },
      },
      response: new Response(null, { status: 403 }),
    });

    await expect(getProfessionalNotifications(client)).rejects.toMatchObject({
      code: "forbidden",
      requestId: "notifications-denied",
    });
  });
});
