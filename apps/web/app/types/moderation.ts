export interface ModerationQueueItem {
  id: string;
  type: string;
  title: string;
  subtitle: string;
  submittedAt: string;
  age: string;
  details: string;
  preview: string;
}

export type ModerationDecision = "approved" | "rejected";
