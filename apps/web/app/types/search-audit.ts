export type SearchAuditStatus =
  | "processing"
  | "completed"
  | "application_rate_limited"
  | "provider_rate_limited"
  | "provider_unavailable"
  | "response_rejected"
  | "search_failed";

export interface SearchAuditParsedResponse {
  serviceIds: string[];
  services: Array<{ id: string; name: string }>;
  locations: Array<{
    stateCode: string;
    city: string;
    neighborhood: { code: string; name: string } | null;
  }>;
  keywords: string[];
  normalizedRequest: string | null;
}

export interface SearchAuditItem {
  id: string;
  inputPrompt: string;
  rawLlmResponse: string | null;
  parsedResponse: SearchAuditParsedResponse | null;
  status: SearchAuditStatus;
  responseSource: "provider" | "cache" | null;
  adapter: string | null;
  model: string | null;
  providerRequestId: string | null;
  promptDigest: string | null;
  resultCount: number;
  createdAt: string;
}

export interface SearchAuditPage {
  items: SearchAuditItem[];
  meta: {
    page: number;
    perPage: number;
    totalCount: number;
    totalPages: number;
  };
}
