import type { ServiceAdjustmentItemKind } from "./service-job";

export interface ToastMessage {
  title: string;
  description: string;
}

export interface LegalDocumentSection {
  id: string;
  label: string;
}

export type AppRole = "visitor" | "professional" | "admin";

export interface ServiceAdjustmentEditorItem {
  key: string;
  kind: ServiceAdjustmentItemKind;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  mediaUploadId: string | null;
  receiptFile: File | null;
}

export interface ServiceAdjustmentEditorForm {
  title: string;
  description: string;
  scheduleImpact: string;
  incurredOn: string;
  items: ServiceAdjustmentEditorItem[];
}

export type ServiceAdjustmentEditorSaveIntent = "draft" | "copy" | "whatsapp";

export interface ExpressionSearchPayload {
  expression: string;
}

export interface SearchLocation {
  cityCode: string;
  stateCode: string;
  city: string;
  stateSlug: string;
  citySlug: string;
}

export type SearchLocationSource = "ip" | "fallback" | "manual";

export interface StructuredSearchCity {
  id: string;
  name: string;
  stateCode: string;
  stateSlug: string;
  citySlug: string;
}

export interface StructuredSearchPayload {
  serviceId: string;
  serviceName: string;
  cityCode: string;
  city: string;
  stateCode: string;
  stateSlug: string;
  citySlug: string;
}
