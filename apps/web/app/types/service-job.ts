export type ServiceJobStatus =
  | "approved"
  | "completion_requested"
  | "completion_issue"
  | "completed"
  | "cancelled";

export interface ProfessionalServiceJob {
  id: string;
  status: ServiceJobStatus;
  quote: {
    id: string;
    number: number;
    customerName: string;
    customerPhone: string;
    customerEmail: string;
    serviceDescription: string;
    serviceAddress: string;
    scheduledOn: string;
    total: number;
  };
  completionRequestedAt: string | null;
  completionIssueAt: string | null;
  completionIssueMessage: string;
  completedAt: string | null;
  cancelledAt: string | null;
  cancellationReason: string;
  recommendationRequestStatus: "open" | "completed" | "expired" | null;
  createdAt: string;
  updatedAt: string;
}
