import type { BerufeApiClient } from "@app/services/api/client";
import {
  createProfessionalQuote,
  fetchProfessionalQuote,
  mapProfessionalQuote,
  shareProfessionalQuote,
  updateProfessionalQuote,
} from "@app/services/api/professional-quotes";
import type { components } from "@app/services/api/schema";

type ContractQuote = components["schemas"]["ProfessionalQuote"];

const contractQuote: ContractQuote = {
  id: "50e943de-3761-41cf-95c6-1fd12d6d3802",
  quote_number: 7,
  customer_name: "Ana Paula",
  service_description: "Adequação elétrica",
  valid_until: "2026-08-25",
  notes: "Materiais a definir.",
  status: "draft",
  subtotal_amount: "13.33",
  discount_amount: "1.33",
  total_amount: "12.00",
  shared_at: null,
  created_at: "2026-08-18T12:00:00Z",
  updated_at: "2026-08-18T12:01:00Z",
  items: [
    {
      id: "490e5e5d-cabb-4f99-a944-3ad69255c8c5",
      description: "Material",
      quantity: "0.333",
      unit: "unidade",
      unit_price: "10.01",
      line_total: "3.33",
      sort_order: 0,
    },
    {
      id: "f7c5a0d6-e285-431e-bf62-c3aa945f36d9",
      description: "Serviço",
      quantity: "1",
      unit: "serviço",
      unit_price: "10.00",
      line_total: "10.00",
      sort_order: 1,
    },
  ],
};

function clientReturning(
  method: "GET" | "POST" | "PATCH",
  quote = contractQuote,
) {
  return {
    [method]: vi.fn().mockResolvedValue({
      data: { data: { quote }, request_id: "quote-request" },
      error: undefined,
      response: new Response(null),
    }),
  } as unknown as BerufeApiClient;
}

describe("professional quote API", () => {
  it("maps authoritative decimal totals and ordered items", () => {
    expect(mapProfessionalQuote(contractQuote)).toMatchObject({
      id: contractQuote.id,
      number: 7,
      subtotal: 13.33,
      discount: 1.33,
      total: 12,
      items: [
        { description: "Material", quantity: 0.333, lineTotal: 3.33 },
        { description: "Serviço", quantity: 1, lineTotal: 10 },
      ],
    });
  });

  it("creates a quote without sending browser-calculated totals", async () => {
    const client = clientReturning("POST");
    const draft = mapProfessionalQuote(contractQuote);
    draft.subtotal = 9999;
    draft.total = 1;
    draft.items[0]!.lineTotal = 777;

    await expect(createProfessionalQuote(client, draft)).resolves.toMatchObject(
      {
        number: 7,
        total: 12,
      },
    );
    expect(client.POST).toHaveBeenCalledWith("/api/v1/professional/quotes", {
      body: {
        quote: {
          customer_name: "Ana Paula",
          service_description: "Adequação elétrica",
          discount_amount: 1.33,
          valid_until: "2026-08-25",
          notes: "Materiais a definir.",
          items: [
            {
              description: "Material",
              quantity: 0.333,
              unit: "unidade",
              unit_price: 10.01,
            },
            {
              description: "Serviço",
              quantity: 1,
              unit: "serviço",
              unit_price: 10,
            },
          ],
        },
      },
    });
  });

  it("loads and updates only the owner-selected opaque quote id", async () => {
    const getClient = clientReturning("GET");
    const patchClient = clientReturning("PATCH");
    const draft = mapProfessionalQuote(contractQuote);

    await fetchProfessionalQuote(getClient, contractQuote.id);
    await updateProfessionalQuote(patchClient, contractQuote.id, draft);

    expect(getClient.GET).toHaveBeenCalledWith(
      "/api/v1/professional/quotes/{id}",
      { params: { path: { id: contractQuote.id } } },
    );
    expect(patchClient.PATCH).toHaveBeenCalledWith(
      "/api/v1/professional/quotes/{id}",
      expect.objectContaining({
        params: { path: { id: contractQuote.id } },
      }),
    );
  });

  it("maps the owner-only secure share response without deriving a browser token", async () => {
    const client = {
      POST: vi.fn().mockResolvedValue({
        data: {
          data: {
            quote: { ...contractQuote, status: "shared" },
            share_url:
              "https://berufe.com.br/orcamento/bq_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
          },
          request_id: "quote-share",
        },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    await expect(
      shareProfessionalQuote(client, contractQuote.id),
    ).resolves.toMatchObject({
      quote: { status: "shared" },
      shareUrl:
        "https://berufe.com.br/orcamento/bq_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    });
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/quotes/{id}/share",
      { params: { path: { id: contractQuote.id } } },
    );
  });
});
