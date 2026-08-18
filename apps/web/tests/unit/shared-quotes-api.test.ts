import type { BerufeApiClient } from "@app/services/api/client";
import type { components } from "@app/services/api/schema";
import { resolveSharedQuote } from "@app/services/api/shared-quotes";

type SharedQuote = components["schemas"]["SharedQuote"];
type SharedProfessional = components["schemas"]["SharedQuoteProfessional"];

const quote: SharedQuote = {
  quote_number: 12,
  customer_name: "Ana Paula",
  service_description: "Iluminação da cozinha",
  valid_until: "2026-01-01",
  notes: "Materiais definidos.",
  subtotal_amount: "13.33",
  discount_amount: "1.33",
  total_amount: "12.00",
  items: [
    {
      description: "Material",
      quantity: "0.333",
      unit: "unidade",
      unit_price: "10.01",
      line_total: "3.33",
      sort_order: 0,
    },
    {
      description: "Serviço",
      quantity: "1",
      unit: "serviço",
      unit_price: "10.00",
      line_total: "10.00",
      sort_order: 1,
    },
  ],
};
const professional: SharedProfessional = {
  display_name: "Ana Souza",
  photo_url: null,
  primary_service: "Eletricista",
  identity_verified: false,
};

describe("shared quote API", () => {
  it("resolves the bearer through a POST body into the narrow customer projection", async () => {
    const client = {
      POST: vi.fn().mockResolvedValue({
        data: {
          data: { quote, professional },
          request_id: "shared-quote",
        },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;
    const token = "bq_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

    await expect(resolveSharedQuote(client, token)).resolves.toEqual({
      quote: {
        id: null,
        number: 12,
        customerName: "Ana Paula",
        serviceDescription: "Iluminação da cozinha",
        validUntil: "2026-01-01",
        discount: 1.33,
        notes: "Materiais definidos.",
        status: "shared",
        subtotal: 13.33,
        total: 12,
        sharedAt: null,
        createdAt: null,
        updatedAt: null,
        items: [
          {
            id: "shared-12-0",
            description: "Material",
            quantity: 0.333,
            unit: "unidade",
            unitPrice: 10.01,
            lineTotal: 3.33,
            sortOrder: 0,
          },
          {
            id: "shared-12-1",
            description: "Serviço",
            quantity: 1,
            unit: "serviço",
            unitPrice: 10,
            lineTotal: 10,
            sortOrder: 1,
          },
        ],
      },
      professional: {
        name: "Ana Souza",
        avatar: null,
        primaryService: "Eletricista",
        identityVerified: false,
      },
    });
    expect(client.POST).toHaveBeenCalledWith("/api/v1/shared-quotes/resolve", {
      body: { token },
    });
  });
});
