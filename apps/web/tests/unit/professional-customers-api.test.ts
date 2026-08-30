import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchProfessionalCustomer,
  fetchProfessionalCustomers,
  mapProfessionalCustomer,
  updateProfessionalCustomer,
} from "@app/services/api/professional-customers";
import type { components } from "@app/services/api/schema";

type ContractCustomer = components["schemas"]["ProfessionalCustomer"];

const customer: ContractCustomer = {
  id: "a3f42858-40bc-4bda-bb66-35f32eece27c",
  name: "Ana Paula",
  whatsapp_e164: "+5547999991111",
  email: "ana@example.com",
  email_verified: true,
  quote_count: 3,
  last_quote_at: "2026-08-18T12:01:00Z",
};

describe("professional customer API", () => {
  it("maps canonical contact details and customer activity", () => {
    expect(mapProfessionalCustomer(customer)).toEqual({
      id: customer.id,
      name: "Ana Paula",
      phone: "(47) 9 9999-1111",
      email: "ana@example.com",
      emailVerified: true,
      quoteCount: 3,
      lastQuoteAt: "2026-08-18T12:01:00Z",
    });
  });

  it("lists customers with owner-scoped search and pagination", async () => {
    const client = {
      GET: vi.fn().mockResolvedValue({
        data: {
          data: {
            customers: [customer],
            meta: {
              page: 2,
              per_page: 20,
              total_count: 21,
              total_pages: 2,
            },
          },
          request_id: "customers-list",
        },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    await expect(
      fetchProfessionalCustomers(client, {
        search: "Ana",
        page: 2,
        perPage: 20,
      }),
    ).resolves.toMatchObject({
      customers: [{ id: customer.id, name: "Ana Paula" }],
      meta: { page: 2, perPage: 20, totalCount: 21, totalPages: 2 },
    });
    expect(client.GET).toHaveBeenCalledWith("/api/v1/professional/customers", {
      params: {
        query: { search: "Ana", page: 2, per_page: 20 },
      },
    });
  });

  it("loads one customer and normalizes updates", async () => {
    const getClient = {
      GET: vi.fn().mockResolvedValue({
        data: { data: { customer }, request_id: "customer-show" },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;
    await expect(
      fetchProfessionalCustomer(getClient, customer.id),
    ).resolves.toMatchObject({ id: customer.id, name: "Ana Paula" });

    const patchClient = {
      PATCH: vi.fn().mockResolvedValue({
        data: { data: { customer }, request_id: "customer-update" },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;
    await updateProfessionalCustomer(patchClient, customer.id, {
      name: "Ana Paula",
      phone: "(47) 9 9999-1111",
      email: " ana@example.com ",
    });

    expect(patchClient.PATCH).toHaveBeenCalledWith(
      "/api/v1/professional/customers/{id}",
      {
        params: { path: { id: customer.id } },
        body: {
          customer: {
            name: "Ana Paula",
            whatsapp_e164: "5547999991111",
            email: "ana@example.com",
          },
        },
      },
    );
  });
});
