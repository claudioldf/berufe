export interface ToastMessage {
  title: string;
  description: string;
}

export interface LegalDocumentSection {
  id: string;
  label: string;
}

export type AppRole = "visitor" | "professional" | "admin";

export interface ServiceSearchPayload {
  service: string;
  neighborhood: string;
}
