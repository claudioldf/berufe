import type { ProfessionalProfileDraft, ProfessionalWorkspace } from "~/types";
import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";

type ContractWorkspace = components["schemas"]["ProfessionalWorkspaceData"];

function nationalPhone(value: string) {
  return value.startsWith("+55") ? value.slice(3) : value;
}

export function mapProfessionalWorkspace(
  data: ContractWorkspace,
): ProfessionalWorkspace {
  const identity = data.profile.identity;
  return {
    profile: {
      id: data.profile.id,
      status: data.profile.profile_status,
      identity: {
        name: identity.display_name,
        headline: identity.headline,
        bio: identity.bio,
        yearsExperience: identity.years_experience ?? 0,
        whatsapp: nationalPhone(identity.whatsapp),
        instagram: identity.instagram ?? "",
        youtube: identity.youtube ?? "",
      },
    },
  };
}

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

export async function fetchProfessionalWorkspace(
  client: BerufeApiClient,
): Promise<ProfessionalWorkspace> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/workspace",
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalWorkspace(data.data);
}

export async function updateProfessionalIdentity(
  client: BerufeApiClient,
  draft: ProfessionalProfileDraft,
): Promise<ProfessionalWorkspace> {
  const { data, error, response } = await client.PATCH(
    "/api/v1/professional/profile",
    {
      body: {
        identity: {
          display_name: draft.name,
          headline: draft.headline,
          bio: draft.bio,
          years_experience: draft.yearsExperience,
          whatsapp: draft.whatsapp,
          instagram: draft.instagram || null,
          youtube: draft.youtube || null,
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalWorkspace(data.data);
}
