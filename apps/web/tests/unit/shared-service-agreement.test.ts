import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import SharedServiceAgreement from "@app/components/quotes/SharedServiceAgreement.vue";
import type { QuoteServiceJob } from "@app/types";

const ButtonStub = defineComponent({
  props: { disabled: Boolean, loading: Boolean },
  emits: ["click"],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
});

const serviceJob: QuoteServiceJob = {
  id: null,
  status: "approved",
  completedAt: null,
  cancelledAt: null,
  originalTotal: 500,
  approvedAdjustmentTotal: 0,
  awaitingDecisionTotal: 80,
  agreedTotal: 500,
  adjustments: [
    {
      id: "a6e57078-9ea2-4fc5-bca9-428f2bfc57db",
      number: 1,
      revision: 1,
      status: "awaiting_response",
      title: "Tinta adicional",
      description: "Uma lata extra para a segunda parede.",
      scheduleImpact: "",
      incurredOn: "2026-09-05",
      total: 80,
      sharedAt: "2026-09-05T12:00:00Z",
      customerDecidedAt: null,
      customerDecisionMessage: "",
      termsAcceptedAt: null,
      acceptedRevision: null,
      items: [
        {
          id: "f9fc45ca-c4af-4f27-a8ad-730456b581c2",
          kind: "material_reimbursement",
          description: "Tinta",
          quantity: 1,
          unit: "lata",
          unitPrice: 80,
          lineTotal: 80,
          sortOrder: 0,
          receipt: null,
        },
      ],
      changeRequests: [],
    },
  ],
};

describe("shared service agreement", () => {
  it("keeps pending money outside the agreed total and discloses missing receipts", () => {
    const wrapper = mount(SharedServiceAgreement, {
      props: { serviceJob, actingAdjustmentId: null },
      global: {
        stubs: {
          UButton: ButtonStub,
          UIcon: true,
          DesignSystemEyebrow: true,
        },
      },
    });

    expect(wrapper.text()).toContain("R$ 500,00");
    expect(wrapper.text()).toContain("R$ 80,00");
    expect(wrapper.text()).toContain("Comprovante não anexado");
    expect(wrapper.text()).toContain(
      "só entra no total combinado se você aprovar",
    );
    expect(wrapper.text()).not.toContain("Ajustes aprovados");

    const list = wrapper.get(".shared-agreement__list").element;
    const summary = wrapper.get(".shared-agreement__summary").element;
    expect(
      list.compareDocumentPosition(summary) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy();
    expect(wrapper.get(".shared-agreement__agreed-total").text()).toContain(
      "R$ 500,00",
    );
  });

  it("describes numeric schedule impacts with the correct plural", async () => {
    const withImpact = structuredClone(serviceJob);
    withImpact.adjustments![0]!.scheduleImpact = "1";
    const wrapper = mount(SharedServiceAgreement, {
      props: { serviceJob: withImpact, actingAdjustmentId: null },
      global: {
        stubs: {
          UButton: ButtonStub,
          UIcon: true,
          DesignSystemEyebrow: true,
        },
      },
    });

    expect(wrapper.text()).toContain("Impacto no prazo: 1 dia a mais");

    const twoDays = structuredClone(withImpact);
    twoDays.adjustments![0]!.scheduleImpact = "2";
    await wrapper.setProps({ serviceJob: twoDays });

    expect(wrapper.text()).toContain("Impacto no prazo: 2 dias a mais");
  });

  it("shows the approved adjustment breakdown only for a positive amount", () => {
    const approved = structuredClone(serviceJob);
    approved.approvedAdjustmentTotal = 120;
    approved.agreedTotal = 620;
    const wrapper = mount(SharedServiceAgreement, {
      props: { serviceJob: approved, actingAdjustmentId: null },
      global: {
        stubs: {
          UButton: ButtonStub,
          UIcon: true,
          DesignSystemEyebrow: true,
        },
      },
    });

    expect(wrapper.text()).toContain("Ajustes aprovados");
    expect(wrapper.text()).toContain("R$ 120,00");
  });

  it("validates and emits approval for the exact adjustment", async () => {
    const wrapper = mount(SharedServiceAgreement, {
      props: { serviceJob, actingAdjustmentId: null },
      global: {
        stubs: {
          UButton: ButtonStub,
          UIcon: true,
          DesignSystemEyebrow: true,
        },
      },
    });
    const approve = wrapper
      .findAll("button")
      .find((button) => button.text().includes("Aprovar ajuste"))!;

    await approve.trigger("click");
    expect(wrapper.text()).toContain("Confirme que revisou este ajuste");
    expect(wrapper.emitted("decide")).toBeUndefined();

    await wrapper.get('input[type="checkbox"]').setValue(true);
    await approve.trigger("click");
    expect(wrapper.emitted("decide")?.[0]).toEqual([
      serviceJob.adjustments![0],
      "approve",
      "",
      true,
    ]);
  });
});
