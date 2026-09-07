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

function mountEditor(itemCount = 1) {
  return mount(AdjustmentItemsEditor, {
    props: {
      modelValue: Array.from({ length: itemCount }, (_, index) => ({
        ...structuredClone(item),
        key: `item-${index + 1}`,
      })),
      total: 150 * itemCount,
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
    const values = wrapper.get(".adjustment-item:not(.adjustment-item--head)");

    expect(values.text()).toContain("Quantidade");
    expect(values.text()).toContain("Valor unitário");
    expect(values.text()).toContain("Total do item");
    expect(values.findComponent(CurrencyInput).exists()).toBe(true);
    expect(values.text()).toContain("R$ 150,00");
  });

  it("places add below the cards, shows the sum, and emits compact actions", async () => {
    const wrapper = mountEditor(2);
    const items = wrapper.get(".adjustment-items").element;
    const add = wrapper.get(".adjustment-items-editor__actions").element;

    expect(
      items.compareDocumentPosition(add) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy();
    expect(wrapper.get(".adjustment-items-editor__summary").text()).toContain(
      "R$ 300,00",
    );

    await wrapper.get('[aria-label="Remover item 1"]').trigger("click");
    expect(wrapper.emitted("remove")?.[0]).toEqual([0]);

    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Adicionar item")!
      .trigger("click");
    expect(wrapper.emitted("add")).toHaveLength(1);
  });

  it("protects the only remaining item from accidental removal", () => {
    const wrapper = mountEditor();

    expect(wrapper.find('[aria-label="Remover item 1"]').exists()).toBe(false);
  });
});
