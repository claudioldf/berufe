import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import QuoteIndex from "~/components/dashboard/quotes/QuoteIndex.vue";
import type { Quote, QuotePage } from "~/types";

function quoteFixture(overrides: Partial<Quote>): Quote {
  return {
    id: "0fd22016-3021-46cc-8e31-a83e2f2d9180",
    number: 12,
    revision: 0,
    customerId: "a3f42858-40bc-4bda-bb66-35f32eece27c",
    customerName: "Ana Paula",
    customerPhone: "(47) 99999-1111",
    customerEmail: "ana@example.com",
    serviceDescription: "Adequação elétrica",
    serviceAddress: "Rua das Flores, 10",
    scheduledOn: "2026-08-22",
    validUntil: "2026-08-25",
    discount: 0,
    notes: "",
    status: "draft",
    subtotal: 100,
    total: 100,
    sharedAt: null,
    createdAt: "2026-08-18T12:00:00Z",
    updatedAt: "2026-08-18T12:00:00Z",
    customerDecisionMessage: "",
    changeRequests: [],
    serviceJob: null,
    items: [],
    ...overrides,
  };
}

const quotes = [
  quoteFixture({ status: "saved" }),
  quoteFixture({
    id: "29bf2d2a-1448-4805-9f86-ae2522c811cc",
    number: 11,
    customerName: "José Silva",
    serviceDescription: "Pintura externa",
    scheduledOn: "2026-08-23",
    total: 300,
    updatedAt: "2026-08-20T12:00:00Z",
    status: "shared",
  }),
  quoteFixture({
    id: "443ad611-202f-43f2-b35f-e8597fcd3f51",
    number: 10,
    customerName: "Maria Souza",
    serviceDescription: "Instalação hidráulica",
    scheduledOn: "",
    total: 200,
    updatedAt: "2026-08-19T12:00:00Z",
    status: "change_requested",
  }),
];

function pageFixture(overrides: Partial<QuotePage> = {}): QuotePage {
  return {
    quotes,
    meta: { page: 1, perPage: 20, totalCount: 3, totalPages: 1 },
    summary: {
      awaitingResponse: { count: 2, total: 450 },
      changesRequested: { count: 1 },
      approvedThisMonth: { count: 3, total: 900 },
    },
    ...overrides,
  };
}

const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});
const NuxtLinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});
const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});

function mountIndex(result = pageFixture()) {
  return mount(QuoteIndex, {
    props: { result },
    global: {
      stubs: {
        DesignSystemSurfaceCard: SurfaceCardStub,
        DesignSystemDisabledTooltip: TooltipStub,
        NuxtLink: NuxtLinkStub,
        UButton: NuxtLinkStub,
        UIcon: true,
      },
    },
  });
}

afterEach(() => {
  vi.useRealTimers();
});

describe("professional quote index", () => {
  it("shows the commercial summary without presenting quote values as payments", () => {
    const wrapper = mountIndex();

    expect(wrapper.get('[aria-label="Aguardando resposta"]').text()).toMatch(
      /R\$\s*450,00/,
    );
    expect(wrapper.get('[aria-label="Aguardando resposta"]').text()).toContain(
      "2 orçamentos",
    );
    expect(wrapper.get('[aria-label="Alterações solicitadas"]').text()).toMatch(
      /1\s*orçamento para revisar/,
    );
    expect(wrapper.get('[aria-label="Aprovados este mês"]').text()).toMatch(
      /R\$\s*900,00/,
    );
    expect(wrapper.text()).toContain(
      "Os valores correspondem aos orçamentos e não indicam pagamentos recebidos.",
    );
  });

  it("renders explicit zero states in the commercial summary", () => {
    const wrapper = mountIndex(
      pageFixture({
        summary: {
          awaitingResponse: { count: 0, total: 0 },
          changesRequested: { count: 0 },
          approvedThisMonth: { count: 0, total: 0 },
        },
      }),
    );

    expect(wrapper.get('[aria-label="Aguardando resposta"]').text()).toMatch(
      /R\$\s*0,00.*0 orçamentos/,
    );
    expect(wrapper.get('[aria-label="Alterações solicitadas"]').text()).toMatch(
      /0\s*orçamentos para revisar/,
    );
    expect(wrapper.get('[aria-label="Aprovados este mês"]').text()).toMatch(
      /R\$\s*0,00.*0 orçamentos/,
    );
  });

  it("renders the server page and keeps the result summary outside the filter card", () => {
    const wrapper = mountIndex();

    expect(wrapper.findAll(".quote-table__row")).toHaveLength(3);
    expect(
      wrapper
        .get(
          'a[href="/app/professional/quotes/new?quote=29bf2d2a-1448-4805-9f86-ae2522c811cc"]',
        )
        .text(),
    ).toContain("Pintura externa");
    expect(wrapper.text()).toContain("Aguardando envio ao cliente");
    expect(wrapper.text()).toContain("1–3 de 3 orçamentos");

    const filters = wrapper.get(".quote-filters");
    const summary = wrapper.get(".quote-index__summary");
    expect(filters.element.contains(summary.element)).toBe(false);
  });

  it("debounces search before requesting a filtered first page", async () => {
    vi.useFakeTimers();
    const wrapper = mountIndex();

    await wrapper.get('input[name="quoteSearch"]').setValue("jose");
    expect(wrapper.emitted("request")).toBeUndefined();

    await vi.advanceTimersByTimeAsync(250);
    expect(wrapper.emitted("request")?.at(-1)).toEqual([
      expect.objectContaining({ search: "jose", page: 1 }),
    ]);
  });

  it("requests backend filtering and clears filters from the external summary row", async () => {
    const wrapper = mountIndex();

    await wrapper
      .get('select[name="quoteStatus"]')
      .setValue("change_requested");
    expect(wrapper.emitted("request")?.at(-1)).toEqual([
      expect.objectContaining({ status: "change_requested", page: 1 }),
    ]);

    await wrapper.get('input[name="quoteScheduledOn"]').setValue("2026-08-23");
    expect(wrapper.emitted("request")?.at(-1)).toEqual([
      expect.objectContaining({
        status: "change_requested",
        scheduledOn: "2026-08-23",
      }),
    ]);

    await wrapper.get(".quote-index__summary button").trigger("click");
    expect(wrapper.emitted("request")?.at(-1)).toEqual([
      expect.objectContaining({ search: "", status: "all", scheduledOn: "" }),
    ]);
    expect(wrapper.find(".quote-index__summary button").exists()).toBe(false);
  });

  it("toggles arrow direction on table columns and requests backend sorting", async () => {
    const wrapper = mountIndex();
    const updated = wrapper.get('button[data-sort="updated"]');

    expect(
      updated.element
        .closest('[role="columnheader"]')
        ?.getAttribute("aria-sort"),
    ).toBe("descending");
    expect(updated.getComponent({ name: "UIcon" }).attributes("name")).toBe(
      "i-lucide-arrow-down",
    );

    await updated.trigger("click");
    expect(wrapper.emitted("request")?.at(-1)).toEqual([
      expect.objectContaining({ sort: "updated", direction: "asc", page: 1 }),
    ]);
    expect(
      updated.element
        .closest('[role="columnheader"]')
        ?.getAttribute("aria-sort"),
    ).toBe("ascending");

    await wrapper.get('button[data-sort="customer"]').trigger("click");
    expect(wrapper.emitted("request")?.at(-1)).toEqual([
      expect.objectContaining({ sort: "customer", direction: "asc", page: 1 }),
    ]);
  });

  it("shows the backend range and requests adjacent pages", async () => {
    const wrapper = mountIndex(
      pageFixture({
        meta: { page: 2, perPage: 20, totalCount: 45, totalPages: 3 },
      }),
    );

    expect(wrapper.text()).toContain("21–40 de 45 orçamentos");
    expect(wrapper.text()).toContain("Página 2 de 3");

    await wrapper.get('button[aria-label="Próxima página"]').trigger("click");
    expect(wrapper.emitted("request")?.at(-1)).toEqual([
      expect.objectContaining({ page: 3, perPage: 20 }),
    ]);
  });

  it("explains disabled sorting and pagination states", async () => {
    const wrapper = mountIndex(
      pageFixture({
        meta: { page: 1, perPage: 20, totalCount: 45, totalPages: 3 },
      }),
    );
    const previous = wrapper.get('button[aria-label="Página anterior"]');

    expect(previous.attributes("disabled")).toBeDefined();
    expect(
      previous.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Você já está na primeira página.");

    await wrapper.setProps({ loading: true });
    const sort = wrapper.get('button[data-sort="updated"]');
    expect(sort.attributes("disabled")).toBeDefined();
    expect(
      sort.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde a atualização da lista de orçamentos.");
    expect(
      previous.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde o carregamento dos orçamentos terminar.");
  });

  it("replaces the first-use quote table with a helpful CTA", () => {
    const wrapper = mountIndex(
      pageFixture({
        quotes: [],
        meta: { page: 1, perPage: 20, totalCount: 0, totalPages: 1 },
      }),
    );

    expect(wrapper.text()).toContain(
      "Transforme pedidos em trabalhos fechados.",
    );
    expect(wrapper.text()).toContain("Aprovação do cliente direto pelo link");
    expect(wrapper.find(".quote-table").exists()).toBe(false);
    expect(wrapper.find(".quote-filters").exists()).toBe(false);
    expect(
      wrapper.get('a[href="/app/professional/quotes/new"]').text(),
    ).toContain("Criar meu primeiro orçamento");
    expect(wrapper.text()).not.toContain("Nenhum orçamento criado ainda.");
  });
});
