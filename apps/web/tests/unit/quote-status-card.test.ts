import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import QuoteStatusCard from "~/components/dashboard/quote/StatusCard.vue";
import type { Quote } from "~/types";

const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});

const quote: Quote = {
  id: null,
  number: null,
  revision: 0,
  customerId: null,
  customerName: "Marina Oliveira",
  customerPhone: "(47) 99999-1111",
  customerEmail: "",
  pricingMode: "fixed_price",
  serviceDescription: "Instalação de luminárias",
  serviceAddress: "",
  scheduledOn: "",
  validUntil: "2026-09-30",
  discount: 0,
  markup: 0,
  notes: "",
  status: "draft",
  subtotal: 300,
  total: 300,
  sharedAt: null,
  createdAt: null,
  updatedAt: null,
  customerDecisionMessage: "",
  changeRequests: [],
  serviceJob: null,
  items: [],
  customerSuppliedMaterials: [],
};

function mountStatus(status: Quote["status"], overrides: Partial<Quote> = {}) {
  return mount(QuoteStatusCard, {
    props: {
      quote: { ...quote, ...overrides, status },
    },
    global: {
      stubs: {
        DesignSystemSurfaceCard: SurfaceCardStub,
        UIcon: true,
      },
    },
  });
}

describe("quote status card", () => {
  it.each([
    ["draft", "Comece seu orçamento", "Rascunho"],
    ["saved", "Pronto para enviar", "Rascunho"],
    ["shared", "Aguardando resposta do cliente", "Enviado"],
    ["change_requested", "Alterações solicitadas", "Enviado"],
    ["approved", "Orçamento aprovado", "Aprovado"],
    ["completed", "Orçamento concluído", "Concluído"],
  ] as const)(
    "presents the %s lifecycle stage",
    (status, expectedTitle, expectedCurrentStep) => {
      const wrapper = mountStatus(status);
      const progress = wrapper.get('[aria-label="Etapas do orçamento"]');

      expect(wrapper.text()).toContain("Status do orçamento");
      expect(wrapper.get("h2").text()).toBe(expectedTitle);
      expect(progress.findAll("strong").map((step) => step.text())).toEqual([
        "Rascunho",
        "Enviado",
        "Aprovado",
        "Concluído",
      ]);
      expect(progress.get('[aria-current="step"]').text()).toContain(
        expectedCurrentStep,
      );
    },
  );

  it("surfaces the latest requested change beside the timeline", () => {
    const wrapper = mountStatus("change_requested", {
      changeRequests: [
        {
          id: "change-1",
          revision: 2,
          message: "Trocar as luminárias por luz quente.",
          requestedAt: "2026-08-31T12:00:00Z",
        },
      ],
    });

    expect(wrapper.get("blockquote").text()).toContain("Pedido do cliente");
    expect(wrapper.get("blockquote").text()).toContain(
      "Trocar as luminárias por luz quente.",
    );
  });

  it("shows a declined branch without marking approval as current", () => {
    const wrapper = mountStatus("declined");
    const progress = wrapper.get('[aria-label="Etapas do orçamento"]');

    expect(wrapper.get("h2").text()).toBe("Orçamento recusado");
    expect(progress.find('[aria-current="step"]').exists()).toBe(false);
    expect(progress.text()).toContain("Decisão do cliente");
  });

  it("shows a cancelled branch after approval without marking completion as current", () => {
    const wrapper = mountStatus("cancelled");
    const progress = wrapper.get('[aria-label="Etapas do orçamento"]');

    expect(wrapper.get("h2").text()).toBe("Orçamento cancelado");
    expect(wrapper.classes()).toContain("status-card--danger");
    expect(progress.classes()).toContain("status-card__progress--muted");
    expect(progress.find('[aria-current="step"]').exists()).toBe(false);
    expect(progress.text()).toContain("Serviço cancelado");
  });
});
