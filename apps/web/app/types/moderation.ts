export type ModerationTargetType =
  | "profile_revision"
  | "profile_photo"
  | "portfolio_item"
  | "verification_request";

export type ModerationTypeFilter = ModerationTargetType | "all";
export type ModerationStatus =
  "pending_review" | "approved" | "rejected" | "hidden";
export type ModerationStatusFilter = ModerationStatus | "all";
export type ModerationDecision =
  "approved" | "rejected" | "hidden" | "restored";

export interface ModerationQueueItem {
  id: string;
  targetType: ModerationTargetType;
  status: ModerationStatus;
  type: string;
  title: string;
  subtitle: string;
  submittedAt: string;
  age: string;
  details: string;
  preview: string;
  hasMedia: boolean;
  verificationFileId: string | null;
}

export interface ModerationPageMeta {
  page: number;
  perPage: number;
  totalCount: number;
  totalPages: number;
}

export interface ModerationSummary {
  pendingCount: number;
  reviewedTodayCount: number;
  oldestPendingAt: string | null;
  oldestPendingAge: string;
}

export interface ModerationQueue {
  items: ModerationQueueItem[];
  meta: ModerationPageMeta;
  summary: ModerationSummary;
}

export interface ModerationFilters {
  type: ModerationTypeFilter;
  status: ModerationStatusFilter;
  search: string;
  page: number;
  perPage: number;
}
