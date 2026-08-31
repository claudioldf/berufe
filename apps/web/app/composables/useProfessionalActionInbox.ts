import { shallowRef } from "vue";
import type { ProfessionalActionKind } from "~/types";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import { shareProfessionalQuote } from "~/services/api/professional-quotes";
import {
  completeProfessionalServiceJob,
  requestProfessionalServiceRecommendation,
} from "~/services/api/professional-service-jobs";

// The state layer behind the dashboard action inbox (S065): each inline
// button dispatches straight to the existing API adapters instead of
// forcing a detour through a quote or service detail page.
export function useProfessionalActionInbox() {
  const client = useApiClient();
  const { showToast } = useToast();
  const actingId = shallowRef<string | null>(null);
  const actionError = shallowRef("");

  function openWhatsapp<T>(action: () => Promise<T & { whatsappUrl: string }>) {
    const handoff = import.meta.client
      ? window.open("about:blank", "_blank")
      : null;
    if (handoff) handoff.opener = null;
    return action()
      .then((result) => {
        if (handoff) handoff.location.replace(result.whatsappUrl);
        else if (import.meta.client) window.location.assign(result.whatsappUrl);
        return result;
      })
      .catch((error) => {
        handoff?.close();
        throw error;
      });
  }

  async function act(id: string, kind: ProfessionalActionKind) {
    if (actingId.value) return;
    actingId.value = id;
    actionError.value = "";
    try {
      if (kind === "quote_unshared" || kind === "quote_awaiting_response") {
        await openWhatsapp(() =>
          shareProfessionalQuote(client, id, "whatsapp"),
        );
        showToast({
          title: "Abrindo o WhatsApp",
          description: "A mensagem já aponta para o telefone deste cliente.",
        });
      } else if (kind === "service_open") {
        await completeProfessionalServiceJob(client, id);
        showToast({
          title: "Serviço concluído",
          description: "Vamos pedir a recomendação ao cliente.",
        });
      } else if (kind === "recommendation_unsent") {
        await openWhatsapp(() =>
          requestProfessionalServiceRecommendation(client, id),
        );
        showToast({
          title: "Abrindo o WhatsApp",
          description: "Peça a recomendação por lá.",
        });
      }
      clearNuxtData("professional-workspace");
    } catch (error) {
      actionError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível concluir a ação.";
    } finally {
      actingId.value = null;
    }
  }

  return { actingId, actionError, act };
}
