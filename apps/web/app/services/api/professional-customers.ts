import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import type {
  CustomerListFilters,
  CustomerPage,
  ProfessionalCustomer,
  ProfessionalCustomerDraft,
} from "~/types";
import {
  formatBrazilianMobilePhone,
  sanitizeBrazilianMobilePhone,
} from "~/utils/brazilian-phone";

type ContractCustomer = components["schemas"]["ProfessionalCustomer"];

export interface ProfessionalCustomerCandidate {
  id: string;
  name: string;
  phone: string;
  email: string;
  emailVerified: boolean;
}

export function defaultProfessionalCustomerListFilters(): CustomerListFilters {
  return { search: "", page: 1, perPage: 20 };
}

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

export function mapProfessionalCustomer(
  customer: ContractCustomer,
): ProfessionalCustomer {
  return {
    id: customer.id,
    name: customer.name,
    phone: formatBrazilianMobilePhone(customer.whatsapp_e164),
    email: customer.email ?? "",
    emailVerified: customer.email_verified,
    quoteCount: customer.quote_count,
    lastQuoteAt: customer.last_quote_at,
  };
}

export async function fetchProfessionalCustomers(
  client: BerufeApiClient,
  filters: CustomerListFilters,
): Promise<CustomerPage> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/customers",
    {
      params: {
        query: {
          search: filters.search || undefined,
          page: filters.page,
          per_page: filters.perPage,
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);

  return {
    customers: data.data.customers.map(mapProfessionalCustomer),
    meta: {
      page: data.data.meta.page,
      perPage: data.data.meta.per_page,
      totalCount: data.data.meta.total_count,
      totalPages: data.data.meta.total_pages,
    },
  };
}

export async function fetchProfessionalCustomer(
  client: BerufeApiClient,
  id: string,
): Promise<ProfessionalCustomer> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/customers/{id}",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalCustomer(data.data.customer);
}

export async function updateProfessionalCustomer(
  client: BerufeApiClient,
  id: string,
  draft: ProfessionalCustomerDraft,
): Promise<ProfessionalCustomer> {
  const { data, error, response } = await client.PATCH(
    "/api/v1/professional/customers/{id}",
    {
      params: { path: { id } },
      body: {
        customer: {
          name: draft.name,
          whatsapp_e164: sanitizeBrazilianMobilePhone(draft.phone),
          email: draft.email.trim() || null,
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalCustomer(data.data.customer);
}

export async function searchProfessionalCustomerCandidates(
  client: BerufeApiClient,
  query: string,
): Promise<ProfessionalCustomerCandidate[]> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/customer-candidates",
    { params: { query: { query } } },
  );
  if (error || !data) {
    throw new ApiRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return data.data.customers.map((customer) => ({
    id: customer.id,
    name: customer.name,
    phone: formatBrazilianMobilePhone(customer.whatsapp_e164),
    email: customer.email ?? "",
    emailVerified: customer.email_verified,
  }));
}
