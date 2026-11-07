import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";

export type SupportTopic =
  "entrar" | "criar-conta" | "excluir-conta" | "editar-perfil" | "geral";

export interface SupportMessageInput {
  name: string;
  email: string;
  phone: string;
  message: string;
  topic: SupportTopic;
}

export async function createSupportMessage(
  client: BerufeApiClient,
  input: SupportMessageInput,
): Promise<void> {
  const phone = input.phone.trim();
  const { data, error, response } = await client.POST(
    "/api/v1/public/support-messages",
    {
      body: {
        support_message: {
          name: input.name.trim(),
          email: input.email.trim(),
          phone: phone || null,
          message: input.message.trim(),
          topic: input.topic,
        },
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
}
