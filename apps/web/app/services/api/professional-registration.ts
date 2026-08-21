import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";

export interface CompleteProfessionalRegistrationInput {
  displayName: string;
  accepted: boolean;
}

export interface CompletedProfessionalRegistration {
  id: string;
  displayName: string;
  profileStatus: "draft" | "published";
}

export async function completeProfessionalRegistration(
  client: BerufeApiClient,
  input: CompleteProfessionalRegistrationInput,
): Promise<CompletedProfessionalRegistration> {
  const { data, error, response } = await client.PUT(
    "/api/v1/professional-registration",
    {
      body: {
        display_name: input.displayName,
        accepted: input.accepted,
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
