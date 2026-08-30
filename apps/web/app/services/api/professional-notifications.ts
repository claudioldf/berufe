import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";
import type { components } from "./schema";
import type {
  ProfessionalNotification,
  ProfessionalNotificationPage,
} from "~/types";

type ContractNotification = components["schemas"]["ProfessionalNotification"];

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

function mapNotification(
  notification: ContractNotification,
): ProfessionalNotification {
  return {
    id: notification.id,
    notificationType: notification.notification_type,
    status: notification.status,
    title: notification.title,
    description: notification.description,
    route: notification.route,
    occurredAt: notification.occurred_at,
    readAt: notification.read_at,
  };
}

export async function getProfessionalNotifications(
  client: BerufeApiClient,
  options: { cursor?: string; limit?: number } = {},
): Promise<ProfessionalNotificationPage> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/notifications",
    { params: { query: options } },
  );
  if (error || !data) throw requestError(error, response);

  return {
    notifications: data.data.notifications.map(mapNotification),
    unreadCount: data.data.unread_count,
    nextCursor: data.data.next_cursor,
  };
}

export async function readProfessionalNotification(
  client: BerufeApiClient,
  id: string,
): Promise<{ notification: ProfessionalNotification; unreadCount: number }> {
  const { data, error, response } = await client.PATCH(
    "/api/v1/professional/notifications/{id}/read",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);

  return {
    notification: mapNotification(data.data.notification),
    unreadCount: data.data.unread_count,
  };
}

export async function readAllProfessionalNotifications(
  client: BerufeApiClient,
): Promise<{ markedReadCount: number; unreadCount: number }> {
  const { data, error, response } = await client.PATCH(
    "/api/v1/professional/notifications/read-all",
  );
  if (error || !data) throw requestError(error, response);

  return {
    markedReadCount: data.data.marked_read_count,
    unreadCount: data.data.unread_count,
  };
}
