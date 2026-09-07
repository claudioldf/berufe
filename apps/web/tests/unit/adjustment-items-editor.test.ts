import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import AdjustmentItemsEditor from "@app/components/dashboard/service/AdjustmentItemsEditor.vue";
import CurrencyInput from "@app/components/design-system/CurrencyInput.vue";
import type { ServiceAdjustmentEditorItem } from "@app/types";

const ButtonStub = defineComponent({
  props: { disabled: Boolean },
  emits: ["click"],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
});

const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});

const item: ServiceAdjustmentEditorItem = {
  key: "item-1",
  kind: "additional_service",
  description: "Pintura adicional",
  quantity: 2,
  unit: "serviço",
  unitPrice: 75,
  mediaUploadId: null,
  receiptFile: null,
};

function mountEditor() {
  return mount(AdjustmentItemsEditor, {
    props: {
      modelValue: [structuredClone(item)],
      total: 150,
      errors: {},
    },
    global: {
      stubs: {
        UButton: ButtonStub,
        UIcon: true,
        DesignSystemSurfaceCard: SurfaceCardStub,
      },
    },
  });
}

describe("adjustment items editor", () => {
  it("offers only additional work and purchase reimbursement", () => {
    const wrapper = mountEditor();
    const optionLabels = wrapper
      .findAll("option")
      .map((option) => option.text());

    expect(optionLabels).toEqual([
      "Serviço adicional",
      "Compra e reembolso de material",
    ]);
    expect(wrapper.text()).not.toContain("Crédito para o cliente");
    expect(wrapper.text()).not.toContain("Material fornecido");
    expect(wrapper.text()).not.toContain("Unidade");
  });

  it("keeps quantity, the currency control, and item total together", () => {
    const wrapper = mountEditor();
    const values = wrapper.get(".adjustment-item__values");

    expect(values.text()).toContain("Quantidade");
    expect(values.text()).toContain("Valor unitário");
    expect(values.text()).toContain("Total do item");
    expect(values.findComponent(CurrencyInput).exists()).toBe(true);
    expect(values.text()).toContain("R$ 150,00");
  });

  it("places add below the cards, shows the sum, and emits compact actions", async () => {
    const wrapper = mountEditor();
    const items = wrapper.get(".adjustment-items-editor__items").element;
    const add = wrapper.get(".adjustment-items-editor__actions").element;

    expect(
      items.compareDocumentPosition(add) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy();
    expect(wrapper.get(".adjustment-items-editor__summary").text()).toContain(
      "R$ 150,00",
    );

    await wrapper.get('[aria-label="Remover item 1"]').trigger("click");
    expect(wrapper.emitted("remove")?.[0]).toEqual([0]);

    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Adicionar item")!
      .trigger("click");
    expect(wrapper.emitted("add")).toHaveLength(1);
  });
});
