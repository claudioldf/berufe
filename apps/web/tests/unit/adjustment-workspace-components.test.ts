import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import AdjustmentSaveBar from "@app/components/dashboard/service/AdjustmentSaveBar.vue";
import AdjustmentStatusCard from "@app/components/dashboard/service/AdjustmentStatusCard.vue";
import type { ServiceAdjustment } from "@app/types";

const ButtonStub = defineComponent({
  props: {
    disabled: Boolean,
    loading: Boolean,
  },
  emits: ["click"],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
});

const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});

const adjustment: ServiceAdjustment = {
  id: "adjustment-1",
  number: 1,
  revision: 1,
  status: "draft",
  title: "Pintura adicional",
  description: "",
  scheduleImpact: "",
  incurredOn: "",
  total: 250,
  sharedAt: null,
  customerDecidedAt: null,
  customerDecisionMessage: "",
  termsAcceptedAt: null,
  acceptedRevision: null,
  items: [],
  changeRequests: [],
};

function mountStatus(overrides: Partial<ServiceAdjustment> = {}) {
  return mount(AdjustmentStatusCard, {
    props: {
      adjustment: { ...adjustment, ...overrides },
    },
    global: {
      stubs: {
        DesignSystemSurfaceCard: SurfaceCardStub,
        UIcon: true,
      },
    },
  });
}

describe("adjustment workspace components", () => {
  it.each([
    ["draft", "Ajuste em rascunho", "Rascunho"],
    ["awaiting_response", "Aguardando resposta do cliente", "Enviado"],
    ["change_requested", "Alterações solicitadas", "Enviado"],
    ["approved", "Ajuste aprovado", "Aprovado"],
  ] as const)(
    "presents the %s lifecycle stage",
    (status, expectedTitle, expectedCurrentStep) => {
      const wrapper = mountStatus({ status });
      const progress = wrapper.get('[aria-label="Etapas do ajuste"]');

      expect(wrapper.get("h2").text()).toBe(expectedTitle);
      expect(progress.findAll("strong").map((step) => step.text())).toEqual([
        "Rascunho",
        "Enviado",
        "Aprovado",
      ]);
      expect(progress.get('[aria-current="step"]').text()).toContain(
        expectedCurrentStep,
      );
    },
  );

  it("surfaces the latest customer request", () => {
    const wrapper = mountStatus({
      status: "change_requested",
      changeRequests: [
        {
          revision: 2,
          message: "Trocar a tinta pela opção lavável.",
          requestedAt: "2026-09-06T12:00:00Z",
        },
      ],
    });

    expect(wrapper.get("blockquote").text()).toContain("Pedido do cliente");
    expect(wrapper.get("blockquote").text()).toContain(
      "Trocar a tinta pela opção lavável.",
    );
  });

  it("offers the same three actions as the quote editor", async () => {
    const wrapper = mount(AdjustmentSaveBar, {
      props: {
        valid: false,
        savingIntent: null,
        error: "",
      },
      global: {
        stubs: {
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });
    const buttons = wrapper.findAll("button");

    expect(buttons.map((button) => button.text())).toEqual([
      "Pré-visualizar",
      "Salvar rascunho",
      "Enviar ao cliente",
    ]);
    expect(wrapper.get('[role="status"]').text()).toContain(
      "Preencha os campos obrigatórios",
    );

    await buttons[0]!.trigger("click");
    await buttons[1]!.trigger("click");
    await buttons[2]!.trigger("click");

    expect(wrapper.emitted("preview")).toHaveLength(1);
    expect(wrapper.emitted("save")).toHaveLength(1);
    expect(wrapper.emitted("share")).toHaveLength(1);
  });
});
