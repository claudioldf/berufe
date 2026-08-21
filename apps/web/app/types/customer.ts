export interface ProfessionalCustomer {
  id: string;
  name: string;
  phone: string;
  email: string;
  emailVerified: boolean;
  quoteCount: number;
  lastQuoteAt: string | null;
}

export interface ProfessionalCustomerDraft {
  name: string;
  phone: string;
  email: string;
}

export interface CustomerListFilters {
  search: string;
  page: number;
  perPage: number;
}

export interface CustomerPageMeta {
  page: number;
  perPage: number;
  totalCount: number;
  totalPages: number;
}

export interface CustomerPage {
  customers: ProfessionalCustomer[];
  meta: CustomerPageMeta;
}
