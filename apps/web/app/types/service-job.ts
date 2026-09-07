export type ServiceJobStatus = "approved" | "completed" | "cancelled";

export type RecommendationDeliveryChannel = "email" | "whatsapp";

export type ServiceAdjustmentStatus =
  | "draft"
  | "awaiting_response"
  | "change_requested"
  | "approved"
  | "declined"
  | "cancelled";

export type ServiceAdjustmentItemKind =
  | "additional_service"
  | "material_charge"
  | "material_reimbursement"
  | "credit";

export interface ServiceAdjustmentItem {
  id: string;
  kind: ServiceAdjustmentItemKind;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  lineTotal: number;
  sortOrder: number;
  receipt: {
    id: string;
    contentType: "image/jpeg" | "image/png";
    mediaUploadId?: string;
  } | null;
}

export interface ServiceAdjustment {
  id: string;
  number: number;
  revision: number;
  status: ServiceAdjustmentStatus;
  title: string;
  description: string;
  scheduleImpact: string;
  incurredOn: string;
  total: number;
  sharedAt: string | null;
  customerDecidedAt: string | null;
  customerDecisionMessage: string;
  termsAcceptedAt: string | null;
  acceptedRevision: number | null;
  acceptedCustomer?: {
    name: string;
    phone: string;
    email: string;
  } | null;
  items: ServiceAdjustmentItem[];
  changeRequests: Array<{
    revision: number;
    message: string;
    requestedAt: string;
  }>;
}

export interface ServiceAdjustmentItemDraft {
  kind: ServiceAdjustmentItemKind;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  mediaUploadId: string | null;
}

export interface ServiceAdjustmentDraft {
  revision?: number;
  title: string;
  description: string;
  scheduleImpact: string;
  incurredOn: string;
  items: ServiceAdjustmentItemDraft[];
}

export interface ProfessionalServiceJobRecommendation {
  status: "open" | "completed" | "expired";
  deliveryChannel: RecommendationDeliveryChannel;
  sentAt: string | null;
}

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
  originalTotal: number;
  approvedAdjustmentTotal: number;
  awaitingDecisionTotal: number;
  agreedTotal: number;
  hasUnresolvedAdjustments: boolean;
  adjustments: ServiceAdjustment[];
  customerFeedbackMessage: string;
  completedAt: string | null;
  cancelledAt: string | null;
  cancellationReason: string;
  recommendation: ProfessionalServiceJobRecommendation | null;
  createdAt: string;
  updatedAt: string;
}
