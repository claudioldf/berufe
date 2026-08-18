export interface QuoteItem {
  id: string;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  lineTotal: number;
  sortOrder: number;
}

export interface Quote {
  id: string | null;
  number: number | null;
  customerName: string;
  serviceDescription: string;
  validUntil: string;
  issuedAt?: string;
  discount: number;
  notes: string;
  status: "draft" | "shared";
  subtotal: number;
  total: number;
  sharedAt: string | null;
  createdAt: string | null;
  updatedAt: string | null;
  items: QuoteItem[];
}

export interface QuoteProfessional {
  name: string;
  avatar: string | null;
  primaryService: string;
  identityVerified: boolean;
}

export type QuoteDraft = Quote;
export type QuoteShareMethod = "whatsapp" | "copy";
