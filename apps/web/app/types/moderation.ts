export type ModerationTargetType = "verification_request";
export type ModerationStatus = "pending_review" | "approved" | "rejected";
export type ModerationStatusFilter = ModerationStatus | "all";
export type ModerationDecision = "approved" | "rejected";

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
  claimedBirthdate: string | null;
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
  status: ModerationStatusFilter;
  search: string;
  page: number;
  perPage: number;
}
