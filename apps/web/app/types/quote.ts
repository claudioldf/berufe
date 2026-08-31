export interface QuoteItem {
  id: string;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  lineTotal: number;
  sortOrder: number;
}

export interface QuoteItemValidationErrors {
  description?: string;
  quantity?: string;
  unit?: string;
  unitPrice?: string;
}

export interface QuoteValidationErrors {
  customerName?: string;
  customerPhone?: string;
  customerEmail?: string;
  serviceDescription?: string;
  serviceAddress?: string;
  scheduledOn?: string;
  validUntil?: string;
  discount?: string;
  notes?: string;
  itemsMessage?: string;
  items: Record<string, QuoteItemValidationErrors>;
}

export interface QuoteChangeRequest {
  id: string;
  revision: number;
  message: string;
  requestedAt: string;
}

export interface Quote {
  id: string | null;
  number: number | null;
  revision: number;
  customerId: string | null;
  customerName: string;
  customerPhone: string;
  customerEmail: string;
  serviceDescription: string;
  serviceAddress: string;
  scheduledOn: string;
  validUntil: string;
  issuedAt?: string;
  discount: number;
  notes: string;
  status:
    "draft" | "saved" | "shared" | "change_requested" | "approved" | "declined";
  subtotal: number;
  total: number;
  sharedAt: string | null;
  createdAt: string | null;
  updatedAt: string | null;
  customerDecisionMessage: string;
  changeRequests: QuoteChangeRequest[];
  serviceJob: QuoteServiceJob | null;
  items: QuoteItem[];
}

export interface QuoteServiceJob {
  id: string | null;
  status: "approved" | "completed" | "cancelled";
  completedAt: string | null;
  cancelledAt: string | null;
}

export interface QuoteProfessional {
  name: string;
  avatar: string | null;
  primaryService: string;
  identityVerified: boolean;
}

export type QuoteDraft = Quote;
export type QuoteShareMethod = "whatsapp" | "copy";
export type QuoteSaveIntent = "draft" | "share";
export type QuoteSortKey =
  "number" | "customer" | "total" | "status" | "updated";
export type QuoteSortDirection = "asc" | "desc";

export interface QuoteListFilters {
  search: string;
  customerId?: string;
  status: Quote["status"] | "all";
  scheduledOn: string;
  sort: QuoteSortKey;
  direction: QuoteSortDirection;
  page: number;
  perPage: number;
}

export interface QuotePageMeta {
  page: number;
  perPage: number;
  totalCount: number;
  totalPages: number;
}

export interface QuoteValueSummary {
  count: number;
  total: number;
}

export interface QuoteCommercialSummary {
  awaitingResponse: QuoteValueSummary;
  changesRequested: {
    count: number;
  };
  approvedThisMonth: QuoteValueSummary;
}

export interface QuotePage {
  quotes: Quote[];
  meta: QuotePageMeta;
  summary: QuoteCommercialSummary;
}
