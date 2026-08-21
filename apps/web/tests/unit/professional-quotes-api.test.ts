import type { BerufeApiClient } from "@app/services/api/client";
import {
  createProfessionalQuote,
  fetchProfessionalQuote,
  fetchProfessionalQuotes,
  mapProfessionalQuote,
  shareProfessionalQuote,
  updateProfessionalQuote,
} from "@app/services/api/professional-quotes";
import type { components } from "@app/services/api/schema";

type ContractQuote = components["schemas"]["ProfessionalQuote"];

const contractQuote: ContractQuote = {
  id: "50e943de-3761-41cf-95c6-1fd12d6d3802",
  quote_number: 7,
  revision: 0,
  customer: {
    id: "a3f42858-40bc-4bda-bb66-35f32eece27c",
    name: "Ana Paula",
    whatsapp_e164: "+5547999991111",
    email: "ana@example.com",
  },
  customer_name: "Ana Paula",
  customer_phone_e164: "+5547999991111",
  customer_email: "ana@example.com",
  service_description: "Adequação elétrica",
  service_address: "Rua das Flores, 10",
  scheduled_on: "2026-08-22",
  valid_until: "2026-08-25",
  notes: "Materiais a definir.",
  status: "draft",
  subtotal_amount: "13.33",
  discount_amount: "1.33",
  total_amount: "12.00",
  shared_at: null,
  customer_decided_at: null,
  customer_decision_message: null,
  change_requests: [
    {
      id: "51bf6ec3-b1f8-47f0-9aae-27f9c9a157d8",
      revision: 2,
      message: "Trocar uma luminária de lugar.",
      requested_at: "2026-08-18T12:00:30Z",
    },
  ],
  service_job: null,
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
      revision: 0,
      customerId: contractQuote.customer.id,
      customerPhone: "(47) 99999-1111",
      customerEmail: "ana@example.com",
      subtotal: 13.33,
      discount: 1.33,
      total: 12,
      changeRequests: [
        {
          revision: 2,
          message: "Trocar uma luminária de lugar.",
          requestedAt: "2026-08-18T12:00:30Z",
        },
      ],
      items: [
        { description: "Material", quantity: 0.333, lineTotal: 3.33 },
        { description: "Serviço", quantity: 1, lineTotal: 10 },
      ],
    });
  });

  it("lists every owner-scoped quote in the API order", async () => {
    const olderQuote: ContractQuote = {
      ...contractQuote,
      id: "b1a906f4-339f-48c2-b70f-6174144701d4",
      quote_number: 6,
      customer_name: "Bruno Lima",
      customer: { ...contractQuote.customer, name: "Bruno Lima" },
    };
    const client = {
      GET: vi.fn().mockResolvedValue({
        data: {
          data: {
            quotes: [contractQuote, olderQuote],
            meta: {
              page: 2,
              per_page: 10,
              total_count: 12,
              total_pages: 2,
            },
          },
          request_id: "quote-list",
        },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;
    const filters = {
      search: "Ana",
      status: "draft" as const,
      scheduledOn: "2026-08-22",
      sort: "customer" as const,
      direction: "asc" as const,
      page: 2,
      perPage: 10,
    };

    await expect(
      fetchProfessionalQuotes(client, filters),
    ).resolves.toMatchObject({
      quotes: [
        { number: 7, customerName: "Ana Paula" },
        { number: 6, customerName: "Bruno Lima" },
      ],
      meta: { page: 2, perPage: 10, totalCount: 12, totalPages: 2 },
    });
    expect(client.GET).toHaveBeenCalledWith("/api/v1/professional/quotes", {
      params: {
        query: {
          search: "Ana",
          status: "draft",
          scheduled_on: "2026-08-22",
          sort: "customer",
          direction: "asc",
          page: 2,
          per_page: 10,
        },
      },
    });
  });

  it("creates a quote without sending browser-calculated totals", async () => {
    const client = clientReturning("POST");
    const draft = mapProfessionalQuote(contractQuote);
    draft.id = null;
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
          customer: {
            id: contractQuote.customer.id,
            name: "Ana Paula",
            whatsapp_e164: "+5547999991111",
            email: "ana@example.com",
          },
          service_description: "Adequação elétrica",
          service_address: "Rua das Flores, 10",
          scheduled_on: "2026-08-22",
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
            whatsapp_url:
              "https://wa.me/?text=Orcamento+https%3A%2F%2Fberufe.com.br%2Forcamento%2Fbq_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
          },
          request_id: "quote-share",
        },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    await expect(
      shareProfessionalQuote(client, contractQuote.id, "copy"),
    ).resolves.toMatchObject({
      quote: { status: "shared" },
      shareUrl:
        "https://berufe.com.br/orcamento/bq_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      whatsappUrl:
        "https://wa.me/?text=Orcamento+https%3A%2F%2Fberufe.com.br%2Forcamento%2Fbq_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    });
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/quotes/{id}/share",
      {
        params: { path: { id: contractQuote.id } },
        body: { share: { method: "copy" } },
      },
    );
  });
});
