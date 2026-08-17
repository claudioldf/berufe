import {
  fetchProfessionalWorkspace,
  updateProfessionalIdentity,
  updateProfessionalProfile,
  updateProfessionalSupply,
} from "~/services/api/professional-workspace";
import type { Neighborhood, ProfessionalProfileDraft, Service } from "~/types";
import { useApiClient } from "~/services/api/client";

export async function useProfessionalWorkspace() {
  const client = useApiClient();
  const workspace = await useAsyncData("professional-workspace", () =>
    fetchProfessionalWorkspace(client),
  );

  async function saveIdentity(draft: ProfessionalProfileDraft) {
    const updated = await updateProfessionalIdentity(client, draft);
    workspace.data.value = updated;
    return updated;
  }

  async function saveSupply(
    draft: ProfessionalProfileDraft,
    services: Service[],
    neighborhoods: Neighborhood[],
  ) {
    const updated = await updateProfessionalSupply(
      client,
      draft,
      services,
      neighborhoods,
    );
    workspace.data.value = updated;
    return updated;
  }

  async function saveProfile(
    draft: ProfessionalProfileDraft,
    services: Service[],
    neighborhoods: Neighborhood[],
  ) {
    const updated = await updateProfessionalProfile(
      client,
      draft,
      services,
      neighborhoods,
    );
    workspace.data.value = updated;
    return updated;
  }

  return {
    ...workspace,
    saveIdentity,
    saveSupply,
    saveProfile,
  };
}
