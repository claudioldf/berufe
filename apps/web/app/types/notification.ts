export type ProfessionalNotificationType =
  | "profile_moderation_approved"
  | "profile_moderation_rejected"
  | "profile_moderation_hidden"
  | "profile_moderation_restored"
  | "profile_photo_moderation_approved"
  | "profile_photo_moderation_rejected"
  | "profile_photo_moderation_hidden"
  | "profile_photo_moderation_restored"
  | "portfolio_item_moderation_approved"
  | "portfolio_item_moderation_rejected"
  | "portfolio_item_moderation_hidden"
  | "portfolio_item_moderation_restored"
  | "verification_request_moderation_approved"
  | "verification_request_moderation_rejected"
  | "relationship_request_received"
  | "relationship_request_accepted"
  | "relationship_request_declined"
  | "quote_change_requested"
  | "quote_approved"
  | "quote_declined"
  | "service_completion_confirmed"
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
