import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import { sanitizeBrazilianMobilePhone } from "~/utils/brazilian-phone";

interface ProfessionalRegistrationBaseInput {
  displayName: string;
  accepted: boolean;
}

export type CompleteProfessionalRegistrationInput =
  ProfessionalRegistrationBaseInput &
    ({ method: "phone"; email: string } | { method: "email"; phone: string });

export interface CompletedProfessionalRegistration {
  id: string;
  displayName: string;
  profileStatus: "draft" | "published";
}

export async function completeProfessionalRegistration(
  client: BerufeApiClient,
  input: CompleteProfessionalRegistrationInput,
): Promise<CompletedProfessionalRegistration> {
  const contact =
    input.method === "phone"
      ? { email: input.email.trim().toLocaleLowerCase("pt-BR") }
      : { phone: sanitizeBrazilianMobilePhone(input.phone) };
  const { data, error, response } = await client.PUT(
    "/api/v1/professional-registration",
    {
      body: {
        display_name: input.displayName,
        accepted: input.accepted,
        ...contact,
      },
    },
  );
  if (error || !data) {
    throw new ApiRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return {
    id: data.data.profile.id,
    displayName: data.data.profile.display_name,
    profileStatus: data.data.profile.profile_status,
  };
}
