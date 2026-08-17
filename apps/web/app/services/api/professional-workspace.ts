import type {
  Neighborhood,
  ProfessionalProfileDraft,
  ProfessionalWorkspace,
  Service,
} from "~/types";
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
      publicSlug: data.profile.public_slug,
      status: data.profile.profile_status,
      revisionStatus: data.profile.revision_status,
      hasPublishedRevision: data.profile.has_published_revision,
      photo: {
        current: data.profile.photo.current
          ? {
              id: data.profile.photo.current.id,
              status: data.profile.photo.current.status,
              rejectionReason: data.profile.photo.current.rejection_reason,
              submittedAt: data.profile.photo.current.submitted_at,
            }
          : null,
        hasPublishedPhoto: data.profile.photo.has_published_photo,
        latestUpload: data.profile.photo.latest_upload
          ? {
              id: data.profile.photo.latest_upload.id,
              state: data.profile.photo.latest_upload.state,
              failureCode: data.profile.photo.latest_upload.failure_code,
              retryable: data.profile.photo.latest_upload.retryable,
            }
          : null,
      },
      portfolioItems: data.profile.portfolio_items.map((item) => ({
        id: item.id,
        title: item.title,
        service: item.service.name,
        description: item.description ?? "",
        image: item.image_url,
        status: item.status,
        rejectionReason: item.rejection_reason,
        submittedAt: item.submitted_at,
      })),
      verification: {
        current: data.profile.verification.current
          ? {
              id: data.profile.verification.current.id,
              verificationType:
                data.profile.verification.current.verification_type,
              status: data.profile.verification.current.status,
              rejectionReason:
                data.profile.verification.current.rejection_reason,
              submittedAt: data.profile.verification.current.submitted_at,
            }
          : null,
      },
      identity: {
        name: identity.display_name,
        headline: identity.headline,
        bio: identity.bio,
        yearsExperience: identity.years_experience ?? 0,
        whatsapp: nationalPhone(identity.whatsapp),
        instagram: identity.instagram ?? "",
        youtube: identity.youtube ?? "",
      },
      services: data.profile.services.map((selection) => ({
        id: selection.id,
        name: selection.name,
        isPrimary: selection.is_primary,
        note: selection.note ?? "",
      })),
      coverage: {
        allJoinville: data.profile.coverage.all_joinville,
        neighborhoods: data.profile.coverage.neighborhoods,
      },
    },
  };
}

function supplyBody(
  draft: ProfessionalProfileDraft,
  services: Service[],
  neighborhoods: Neighborhood[],
) {
  const catalogServices = new Map(
    services.map((service) => [service.name, service]),
  );
  const catalogNeighborhoods = new Map(
    neighborhoods.map((neighborhood) => [neighborhood.name, neighborhood]),
  );
  return {
    services: draft.selectedServices.map((name) => {
      const service = catalogServices.get(name);
      if (!service) throw new Error("Unknown catalog service selection");
      return {
        service_id: service.id,
        is_primary: name === draft.primaryService,
        note: draft.serviceNotes[name] || null,
      };
    }),
    coverage: {
      all_joinville: draft.allJoinville,
      neighborhood_codes: draft.allJoinville
        ? []
        : draft.selectedNeighborhoods.map((name) => {
            const neighborhood = catalogNeighborhoods.get(name);
            if (!neighborhood)
              throw new Error("Unknown catalog neighborhood selection");
            return neighborhood.code;
          }),
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

export async function updateProfessionalSupply(
  client: BerufeApiClient,
  draft: ProfessionalProfileDraft,
  services: Service[],
  neighborhoods: Neighborhood[],
): Promise<ProfessionalWorkspace> {
  const { data, error, response } = await client.PATCH(
    "/api/v1/professional/profile",
    { body: supplyBody(draft, services, neighborhoods) },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalWorkspace(data.data);
}

export async function updateProfessionalProfile(
  client: BerufeApiClient,
  draft: ProfessionalProfileDraft,
  services: Service[],
  neighborhoods: Neighborhood[],
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
        ...supplyBody(draft, services, neighborhoods),
      },
    },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalWorkspace(data.data);
}

export async function submitProfessionalProfile(
  client: BerufeApiClient,
): Promise<ProfessionalWorkspace> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/profile/submission",
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalWorkspace(data.data);
}

export async function attachProfessionalProfilePhoto(
  client: BerufeApiClient,
  mediaUploadId: string,
): Promise<ProfessionalWorkspace> {
  const { data, error, response } = await client.PUT(
    "/api/v1/professional/profile/photo",
    { body: { media_upload_id: mediaUploadId } },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalWorkspace(data.data);
}

export async function attachProfessionalPortfolioItem(
  client: BerufeApiClient,
  input: {
    mediaUploadId: string;
    serviceId: string;
    title: string;
    description: string;
  },
): Promise<ProfessionalWorkspace> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/portfolio-items",
    {
      body: {
        portfolio_item: {
          media_upload_id: input.mediaUploadId,
          service_id: input.serviceId,
          title: input.title,
          description: input.description || null,
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalWorkspace(data.data);
}

export async function deleteProfessionalPortfolioItem(
  client: BerufeApiClient,
  id: string,
): Promise<ProfessionalWorkspace> {
  const { data, error, response } = await client.DELETE(
    "/api/v1/professional/portfolio-items/{id}",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalWorkspace(data.data);
}

export async function attachProfessionalVerificationRequest(
  client: BerufeApiClient,
  mediaUploadId: string,
): Promise<ProfessionalWorkspace> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/verification-requests",
    {
      body: {
        verification_request: {
          media_upload_id: mediaUploadId,
          verification_type: "identity",
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalWorkspace(data.data);
}
