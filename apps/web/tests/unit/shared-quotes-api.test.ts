import type { BerufeApiClient } from "@app/services/api/client";
import type { components } from "@app/services/api/schema";
import { resolveSharedQuote } from "@app/services/api/shared-quotes";

type SharedQuote = components["schemas"]["SharedQuote"];
type SharedProfessional = components["schemas"]["SharedQuoteProfessional"];

const quote: SharedQuote = {
  quote_number: 12,
  revision: 2,
  status: "shared",
  customer_name: "Ana Paula",
  service_description: "Iluminação da cozinha",
  service_address: "Rua das Flores, 10",
  scheduled_on: "2026-08-22",
  valid_until: "2026-01-01",
  notes: "Materiais definidos.",
  total_amount: "12.00",
  customer_decision_message: null,
  service_job: null,
  pricing: {
    mode: "itemized",
    subtotal_amount: "13.33",
    discount_amount: "1.33",
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
  },
  customer_supplied_materials: [
    {
      description: "Tinta acrílica branca 18 L",
      quantity: "2",
      unit: "lata",
      sort_order: 0,
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
        revision: 2,
        customerId: null,
        customerName: "Ana Paula",
        customerPhone: "",
        customerEmail: "",
        pricingMode: "itemized",
        serviceDescription: "Iluminação da cozinha",
        serviceAddress: "Rua das Flores, 10",
        scheduledOn: "2026-08-22",
        validUntil: "2026-01-01",
        discount: 1.33,
        markup: 0,
        notes: "Materiais definidos.",
        status: "shared",
        subtotal: 13.33,
        total: 12,
        sharedAt: null,
        createdAt: null,
        updatedAt: null,
        customerDecisionMessage: "",
        changeRequests: [],
        serviceJob: null,
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
        customerSuppliedMaterials: [
          {
            id: "shared-material-12-0",
            description: "Tinta acrílica branca 18 L",
            quantity: 2,
            unit: "lata",
            sortOrder: 0,
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
