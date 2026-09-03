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
  pricing_mode: "itemized",
  items_visible_to_customer: true,
  subtotal_amount: "13.33",
  discount_amount: "1.33",
  total_amount: "12.00",
  customer_decision_message: null,
  service_job: null,
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
  materials: [
    {
      description: "Fita isolante",
      quantity: "3",
      unit: "rolo",
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
        serviceDescription: "Iluminação da cozinha",
        serviceAddress: "Rua das Flores, 10",
        scheduledOn: "2026-08-22",
        validUntil: "2026-01-01",
        pricingMode: "itemized",
        lumpSumAmount: null,
        itemsVisibleToCustomer: true,
        itemsAmount: 0,
        discount: 1.33,
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
        materials: [
          {
            id: "shared-material-12-0",
            description: "Fita isolante",
            quantity: 3,
            unit: "rolo",
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

  it("maps a closed-price scope item's null price without inventing a value", async () => {
    const lumpSumQuote: SharedQuote = {
      ...quote,
      pricing_mode: "lump_sum",
      items_visible_to_customer: true,
      items: [
        {
          description: "Pintura das paredes",
          quantity: "60",
          unit: "m²",
          unit_price: null,
          line_total: null,
          sort_order: 0,
        },
      ],
    };
    const client = {
      POST: vi.fn().mockResolvedValue({
        data: {
          data: { quote: lumpSumQuote, professional },
          request_id: "shared-quote-lump-sum",
        },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    const result = await resolveSharedQuote(client, "bq_token");

    expect(result.quote.pricingMode).toBe("lump_sum");
    expect(result.quote.items).toEqual([
      {
        id: "shared-12-0",
        description: "Pintura das paredes",
        quantity: 60,
        unit: "m²",
        unitPrice: 0,
        lineTotal: 0,
        sortOrder: 0,
      },
    ]);
  });
});
