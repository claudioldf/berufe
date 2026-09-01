import type { BerufeApiClient } from "@app/services/api/client";
import {
  completeProfessionalServiceJob,
  mapProfessionalServiceJob,
} from "@app/services/api/professional-service-jobs";
import type { components } from "@app/services/api/schema";

type ContractServiceJob = components["schemas"]["ProfessionalServiceJob"];

const contractServiceJob: ContractServiceJob = {
  id: "7a2ffba8-2e04-4237-94e6-3bc06c2de888",
  status: "completed",
  quote: {
    id: "50e943de-3761-41cf-95c6-1fd12d6d3802",
    quote_number: 7,
    customer_name: "Ana Paula",
    customer_phone_e164: "+5547999991111",
    customer_email: "ana@example.com",
    service_description: "Adequação elétrica",
    service_address: "Rua das Flores, 10",
    scheduled_on: "2026-08-22",
    total_amount: "120.00",
  },
  customer_feedback_message: null,
  completed_at: "2026-08-29T15:00:00Z",
  cancelled_at: null,
  cancellation_reason: null,
  recommendation: {
    status: "open",
    delivery_channel: "email",
    sent_at: "2026-08-29T15:00:05Z",
  },
  created_at: "2026-08-29T12:00:00Z",
  updated_at: "2026-08-29T15:00:00Z",
};

describe("professional service jobs API", () => {
  it("maps a completed service and its recommendation delivery", () => {
    expect(mapProfessionalServiceJob(contractServiceJob)).toMatchObject({
      id: contractServiceJob.id,
      status: "completed",
      completedAt: "2026-08-29T15:00:00Z",
      recommendation: {
        status: "open",
        deliveryChannel: "email",
        sentAt: "2026-08-29T15:00:05Z",
      },
    });
  });

  it("lets the professional complete an owned service", async () => {
    const client = {
      POST: vi.fn().mockResolvedValue({
        data: {
          data: {
            service_job: contractServiceJob,
            share_url: null,
            whatsapp_url: null,
          },
          request_id: "service-complete",
        },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    await expect(
      completeProfessionalServiceJob(client, contractServiceJob.id, true),
    ).resolves.toMatchObject({
      serviceJob: { status: "completed" },
      shareUrl: null,
      whatsappUrl: null,
    });
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/service-jobs/{id}/complete",
      {
        params: { path: { id: contractServiceJob.id } },
        body: { completion: { request_recommendation: true } },
      },
    );
  });
});
