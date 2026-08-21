import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import { formatBrazilianMobilePhone } from "~/utils/brazilian-phone";

export interface ProfessionalCustomerCandidate {
  id: string;
  name: string;
  phone: string;
  email: string;
  emailVerified: boolean;
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
