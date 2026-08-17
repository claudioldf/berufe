import {
  fetchProfessionalWorkspace,
  updateProfessionalIdentity,
} from "~/services/api/professional-workspace";
import type { ProfessionalProfileDraft } from "~/types";
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

  return {
    ...workspace,
    saveIdentity,
  };
}
