import { mount } from "@vue/test-utils";
import DisabledTooltip from "@app/components/design-system/DisabledTooltip.vue";

const TooltipStub = {
  props: ["text", "disabled", "open"],
  emits: ["update:open"],
  template: `<div :data-text="text" :data-tooltip-disabled="disabled"><slot /></div>`,
};

function mountWrapped(reason: string | null, loading = false) {
  return mount(DisabledTooltip, {
    props: { reason, loading },
    slots: { default: '<button type="button" disabled>Compartilhar</button>' },
    global: { stubs: { UTooltip: TooltipStub } },
  });
}

describe("DesignSystemDisabledTooltip", () => {
  it("keeps the tooltip disabled and the trigger unfocusable when there is no reason", () => {
    const wrapper = mountWrapped(null);

    const tooltip = wrapper.get("[data-tooltip-disabled]");
    expect(tooltip.attributes("data-tooltip-disabled")).toBe("true");
    const trigger = wrapper.get("span");
    expect(trigger.attributes("tabindex")).toBe("-1");
    expect(trigger.attributes("aria-disabled")).toBe("false");
  });

  it("passes the reason through and makes the trigger focusable when disabled", () => {
    const wrapper = mountWrapped("Conta suspensa.");

    const tooltip = wrapper.get("[data-tooltip-disabled]");
    expect(tooltip.attributes("data-tooltip-disabled")).toBe("false");
    expect(tooltip.attributes("data-text")).toBe("Conta suspensa.");
    const trigger = wrapper.get("span");
    expect(trigger.attributes("tabindex")).toBe("0");
    expect(trigger.attributes("aria-disabled")).toBe("true");
  });

  it("toggles open on click only when there is a reason to show", async () => {
    const withoutReason = mountWrapped(null);
    await withoutReason.get("span").trigger("click");
    expect(withoutReason.emitted("update:open")).toBeUndefined();

    const withReason = mountWrapped("Conta suspensa.");
    await withReason.get("span").trigger("click");
    expect(withReason.findComponent(TooltipStub).props("open")).toBe(true);
    await withReason.get("span").trigger("click");
    expect(withReason.findComponent(TooltipStub).props("open")).toBe(false);
  });

  it("hides and closes the disabled reason while the control is loading", async () => {
    const wrapper = mountWrapped("Conta suspensa.");
    const trigger = wrapper.get(".disabled-tooltip");

    await trigger.trigger("click");
    expect(wrapper.findComponent(TooltipStub).props("open")).toBe(true);

    await wrapper.setProps({ loading: true });

    const tooltip = wrapper.get("[data-tooltip-disabled]");
    expect(tooltip.attributes("data-tooltip-disabled")).toBe("true");
    expect(tooltip.attributes("data-text")).toBeUndefined();
    expect(trigger.attributes("tabindex")).toBe("-1");
    expect(trigger.attributes("aria-disabled")).toBe("false");
    expect(wrapper.findComponent(TooltipStub).props("open")).toBe(false);
  });

  it("opens on touch tap without the compatibility click closing it", async () => {
    const wrapper = mountWrapped("Conta suspensa.");
    const trigger = wrapper.get(".disabled-tooltip");

    await trigger.trigger("pointerup", { pointerType: "touch" });
    expect(wrapper.findComponent(TooltipStub).props("open")).toBe(true);

    await trigger.trigger("click");
    expect(wrapper.findComponent(TooltipStub).props("open")).toBe(true);

    await trigger.trigger("pointerup", { pointerType: "touch" });
    expect(wrapper.findComponent(TooltipStub).props("open")).toBe(false);
  });

  it("still renders the wrapped control regardless of the reason", () => {
    const wrapper = mountWrapped(null);
    expect(wrapper.get("button").text()).toBe("Compartilhar");
  });
});
