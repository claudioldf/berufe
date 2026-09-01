import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import CustomerContactForm from "@app/components/dashboard/customers/CustomerContactForm.vue";
import CustomerDirectory from "@app/components/dashboard/customers/CustomerDirectory.vue";
import type { CustomerPage, ProfessionalCustomer } from "@app/types";

const customer: ProfessionalCustomer = {
  id: "a3f42858-40bc-4bda-bb66-35f32eece27c",
  name: "Ana Paula",
  phone: "(47) 99999-1111",
  email: "ana@example.com",
  emailVerified: true,
  quoteCount: 3,
  lastQuoteAt: "2026-08-18T12:01:00Z",
};
const page: CustomerPage = {
  customers: [customer],
  meta: { page: 1, perPage: 20, totalCount: 1, totalPages: 1 },
};
const emptyPage: CustomerPage = {
  customers: [],
  meta: { page: 1, perPage: 20, totalCount: 0, totalPages: 1 },
};
const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});
const NuxtLinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});
const FieldStub = defineComponent({
  props: { label: { type: String, required: true } },
  template:
    '<label>{{ label }}<slot :control-id="label" :described-by="undefined" :invalid="false" :required="false" /></label>',
});
const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});

afterEach(() => vi.useRealTimers());

describe("customer directory", () => {
  it("renders owner activity and debounces contact search", async () => {
    vi.useFakeTimers();
    const wrapper = mount(CustomerDirectory, {
      props: { result: page },
      global: {
        stubs: {
          DesignSystemSurfaceCard: SurfaceCardStub,
          NuxtLink: NuxtLinkStub,
          UButton: NuxtLinkStub,
          UIcon: true,
        },
      },
    });

    expect(wrapper.text()).toContain("3 orçamentos");
    expect(
      wrapper.get(`[href="/app/professional/customers/${customer.id}"]`),
    ).toBeTruthy();
    await wrapper.get('input[name="customerSearch"]').setValue("Ana");
    expect(wrapper.emitted("request")).toBeUndefined();
    await vi.advanceTimersByTimeAsync(300);
    expect(wrapper.emitted("request")?.at(-1)).toEqual([
      { search: "Ana", page: 1, perPage: 20 },
    ]);
  });

  it("replaces the first-use customer list with a helpful CTA", () => {
    const wrapper = mount(CustomerDirectory, {
      props: { result: emptyPage },
      global: {
        stubs: {
          DesignSystemSurfaceCard: SurfaceCardStub,
          NuxtLink: NuxtLinkStub,
          UButton: NuxtLinkStub,
          UIcon: true,
        },
      },
    });

    expect(wrapper.text()).toContain(
      "Cada orçamento começa a construir sua carteira.",
    );
    expect(wrapper.text()).toContain("Histórico de propostas por cliente");
    expect(wrapper.find('input[name="customerSearch"]').exists()).toBe(false);
    expect(
      wrapper.get('a[href="/app/professional/quotes/new"]').text(),
    ).toContain("Criar meu primeiro orçamento");
    expect(wrapper.text()).not.toContain("Nenhum cliente encontrado");
  });

  it("submits editable contact details and explains snapshot behavior", async () => {
    const wrapper = mount(CustomerContactForm, {
      props: { customer },
      global: {
        stubs: {
          DesignSystemSurfaceCard: SurfaceCardStub,
          DesignSystemFormField: FieldStub,
          DesignSystemEyebrow: true,
          DesignSystemDisabledTooltip: TooltipStub,
          UIcon: true,
        },
      },
    });

    expect(
      wrapper.get<HTMLInputElement>('input[name="customerPhone"]').element
        .value,
    ).toBe("(47) 9 9999-1111");
    await wrapper.get('input[name="customerName"]').setValue("Ana Atualizada");
    await wrapper.get("form").trigger("submit");
    expect(wrapper.emitted("save")).toEqual([
      [
        {
          name: "Ana Atualizada",
          phone: "(47) 99999-1111",
          email: "ana@example.com",
        },
      ],
    ]);
    expect(wrapper.text()).toContain(
      "orçamentos anteriores continuam como estavam",
    );

    await wrapper.setProps({ saving: true });
    const save = wrapper.get('button[type="submit"]');
    expect(save.attributes("disabled")).toBeDefined();
    expect(
      save.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde o salvamento dos dados do cliente terminar.");
  });
});
