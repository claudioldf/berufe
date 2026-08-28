export interface ToastMessage {
  title: string;
  description: string;
}

export interface LegalDocumentSection {
  id: string;
  label: string;
}

export type AppRole = "visitor" | "professional" | "admin";

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
