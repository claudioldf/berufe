export interface QuoteItem {
  id: number;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
}

export interface Quote {
  number: number;
  customerName: string;
  serviceDescription: string;
  validUntil: string;
  issuedAt?: string;
  discount: number;
  notes: string;
  items: QuoteItem[];
}

export type QuoteDraft = Quote;
export type QuoteShareMethod = "whatsapp" | "copy";
