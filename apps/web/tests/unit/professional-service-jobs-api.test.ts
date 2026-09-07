import type { BerufeApiClient } from "@app/services/api/client";
import {
  createProfessionalServiceAdjustment,
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
  original_total_amount: "120.00",
  approved_adjustment_amount: "30.00",
  awaiting_decision_amount: "0.00",
  agreed_total_amount: "150.00",
  has_unresolved_adjustments: false,
  adjustments: [
    {
      id: "a6e57078-9ea2-4fc5-bca9-428f2bfc57db",
      adjustment_number: 1,
      revision: 2,
      status: "approved",
      title: "Material adicional",
      description: null,
      schedule_impact: null,
      incurred_on: "2026-08-28",
      total_amount: "30.00",
      shared_at: "2026-08-28T12:00:00Z",
      customer_decided_at: "2026-08-28T13:00:00Z",
      customer_decision_message: null,
      terms_accepted_at: "2026-08-28T13:00:00Z",
      accepted_revision: 1,
      accepted_customer: {
        name: "Ana Paula",
        phone_e164: "+5547999991111",
        email: "ana@example.com",
      },
      items: [
        {
          id: "f9fc45ca-c4af-4f27-a8ad-730456b581c2",
          kind: "material_reimbursement",
          description: "Tinta",
          quantity: "1",
          unit: "lata",
          unit_price: "30.00",
          line_total: "30.00",
          sort_order: 0,
          receipt: null,
        },
      ],
      change_requests: [],
    },
  ],
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
      agreedTotal: 150,
      adjustments: [
        {
          number: 1,
          total: 30,
          incurredOn: "2026-08-28",
        },
      ],
    });
  });

  it("creates a server-calculated adjustment from the editor draft", async () => {
    const client = {
      POST: vi.fn().mockResolvedValue({
        data: {
          data: { service_job: contractServiceJob },
          request_id: "adjustment-create",
        },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    await expect(
      createProfessionalServiceAdjustment(client, contractServiceJob.id, {
        title: "Tinta adicional",
        description: "",
        scheduleImpact: "",
        incurredOn: "2026-08-28",
        items: [
          {
            kind: "material_reimbursement",
            description: "Tinta",
            quantity: 1,
            unit: "lata",
            unitPrice: 30,
            mediaUploadId: null,
          },
        ],
      }),
    ).resolves.toMatchObject({ agreedTotal: 150 });
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/service-jobs/{service_job_id}/adjustments",
      expect.objectContaining({
        body: {
          adjustment: expect.objectContaining({
            title: "Tinta adicional",
            description: null,
            items: [expect.objectContaining({ unit_price: 30 })],
          }),
        },
      }),
    );
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
