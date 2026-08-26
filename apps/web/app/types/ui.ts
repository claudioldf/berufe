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
  stateCode: "SC";
  city: "Joinville";
  stateSlug: "sc";
  citySlug: "joinville";
}

export type SearchLocationSource = "ip" | "fallback" | "manual";

export interface StructuredSearchCity {
  id: string;
  name: "Joinville";
  stateCode: "SC";
}

export interface StructuredSearchPayload {
  serviceId: string;
  serviceName: string;
  stateCode: "SC";
  city: "Joinville";
}
