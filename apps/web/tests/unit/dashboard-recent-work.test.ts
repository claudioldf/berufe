import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import DashboardRecentWork from "@app/components/dashboard/DashboardRecentWork.vue";

const LinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});

const mountOptions = {
  global: {
    stubs: {
      NuxtLink: LinkStub,
      UButton: LinkStub,
      UIcon: true,
      DesignSystemEyebrow: { template: "<span><slot /></span>" },
      DesignSystemSurfaceCard: {
        template: '<section class="quotes-table"><slot /></section>',
      },
    },
  },
} as const;

describe("dashboard recent work", () => {
  it("shows newest quotes first with status beside the quote number", () => {
    const wrapper = mount(DashboardRecentWork, {
      ...mountOptions,
      props: {
        quotes: [
          {
            id: "quote-id",
            number: 42,
            revision: 1,
            customerName: "Marina Cliente",
            serviceDescription: "Instalação de luminárias",
            total: 1250,
            status: "shared",
            serviceJobStatus: null,
            createdAt: "2026-08-23T12:00:00Z",
          },
          {
            id: "newest-quote-id",
            number: 43,
            revision: 1,
            customerName: "Joana Cliente",
            serviceDescription: "Reparo no quadro elétrico",
            total: 980,
            status: "approved",
            serviceJobStatus: "approved",
            createdAt: "2026-08-23T15:00:00Z",
          },
        ],
        services: [
          {
            id: "service-id",
            status: "approved",
            quote: {
              id: "service-quote-id",
              number: 41,
              customerName: "Paulo Cliente",
              customerPhone: "47999991111",
              customerEmail: "paulo@example.com",
              serviceDescription: "Revisão elétrica",
              serviceAddress: "Joinville, SC",
              scheduledOn: "2026-08-25",
              total: 740,
            },
            completionRequestedAt: null,
            completionIssueAt: null,
            completionIssueMessage: "",
            completedAt: null,
            cancelledAt: null,
            cancellationReason: "",
            recommendationRequestStatus: null,
            createdAt: "2026-08-22T12:00:00Z",
            updatedAt: "2026-08-23T13:00:00Z",
          },
        ],
      },
    });

    const text = wrapper.text();
    expect(text.indexOf("Orçamentos recentes.")).toBeLessThan(
      text.indexOf("Serviços em andamento."),
    );
    expect(text).toContain("Marina Cliente");
    expect(text).toContain("Aguardando resposta");
    expect(text).toContain("Paulo Cliente");
    expect(text).toContain("Aprovado");
    const quoteTable = wrapper.find(".quotes-table--quotes");
    expect(
      quoteTable
        .find(".quotes-table__head")
        .findAll("span")
        .map((column) => column.text()),
    ).toEqual(["Orçamento", "Cliente", "Valor", "Data"]);
    expect(quoteTable.find(".quotes-table__head").text()).not.toContain(
      "Status",
    );
    expect(quoteTable.find(".quotes-table__quote-heading").text()).toContain(
      "#43Aprovado",
    );
    expect(quoteTable.find(".quotes-table__description").text()).toBe(
      "Reparo no quadro elétrico",
    );
    expect(
      wrapper
        .findAll(".quotes-table > a")
        .map((link) => link.attributes("href")),
    ).toEqual([
      "/app/professional/quotes/new?quote=newest-quote-id",
      "/app/professional/quotes/new?quote=quote-id",
      "/app/professional/services/service-id",
    ]);
  });

  it("explains the quote workflow with a first-quote CTA and no blank table", () => {
    const wrapper = mount(DashboardRecentWork, {
      ...mountOptions,
      props: { quotes: [], services: [] },
    });

    expect(wrapper.text()).toContain(
      "Transforme pedidos em trabalhos fechados.",
    );
    expect(wrapper.text()).toContain(
      "O cliente recebe um link seguro para aprovar ou pedir ajustes",
    );
    expect(wrapper.text()).not.toContain("Nenhum orçamento criado ainda.");
    expect(wrapper.text()).not.toContain("Ferramentas");
    expect(wrapper.text()).not.toContain("Orçamentos recentes.");
    expect(wrapper.find(".quotes-table__head").exists()).toBe(false);
    const cta = wrapper
      .findAll("a")
      .find((link) => link.text().includes("Criar meu primeiro orçamento"));
    expect(cta?.attributes("href")).toBe("/app/professional/quotes/new");
    expect(wrapper.text()).not.toContain("Serviços em andamento.");
  });
});
