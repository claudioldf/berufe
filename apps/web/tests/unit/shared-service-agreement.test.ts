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
