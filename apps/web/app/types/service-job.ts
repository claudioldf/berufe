export type ServiceJobStatus = "approved" | "completed" | "cancelled";

export type RecommendationDeliveryChannel = "email" | "whatsapp";

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
  customerFeedbackMessage: string;
  completedAt: string | null;
  cancelledAt: string | null;
  cancellationReason: string;
  recommendation: ProfessionalServiceJobRecommendation | null;
  createdAt: string;
  updatedAt: string;
}
