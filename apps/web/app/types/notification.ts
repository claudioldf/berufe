export type ProfessionalNotificationType =
  | "profile_moderation_hidden"
  | "profile_moderation_restored"
  | "verification_request_moderation_approved"
  | "verification_request_moderation_rejected"
  | "relationship_request_received"
  | "relationship_request_accepted"
  | "relationship_request_declined"
  | "quote_change_requested"
  | "quote_approved"
  | "quote_declined"
  | "service_completion_issue_reported"
  | "customer_recommendation_published";

export interface ProfessionalNotification {
  id: string;
  notificationType: ProfessionalNotificationType;
  status: "unread" | "read";
  title: string;
  description: string;
  route: string;
  occurredAt: string;
  readAt: string | null;
}

export interface ProfessionalNotificationPage {
  notifications: ProfessionalNotification[];
  unreadCount: number;
  nextCursor: string | null;
}
