import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import QuoteBuilder from "~/components/dashboard/QuoteBuilder.vue";
import type { Quote, QuoteProfessional } from "~/types";

const quote: Quote = {
  id: "4ec62fe9-f61a-4df0-967f-628cd9a05486",
  number: 12,
  revision: 0,
  customerId: "a3f42858-40bc-4bda-bb66-35f32eece27c",
  customerName: "Ana Paula",
  customerPhone: "(47) 99999-1111",
  customerEmail: "ana@example.com",
  serviceDescription: "Iluminação da cozinha",
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
  items: [
    {
      id: "0cfa24cf-dd67-4ff5-b0ea-e9812fa97766",
      description: "Instalação",
      quantity: 1,
      unit: "serviço",
      unitPrice: 100,
      lineTotal: 100,
      sortOrder: 0,
    },
  ],
};
const professional: QuoteProfessional = {
  name: "Ana Souza",
  avatar: null,
  primaryService: "Eletricista",
  identityVerified: true,
};
const ModalStub = defineComponent({
  template: '<div><slot name="body" /><slot name="footer" /></div>',
});
const ButtonStub = defineComponent({
  props: { disabled: Boolean, loading: Boolean },
  emits: ["click"],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
});
const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});
const SaveBarStub = defineComponent({
  props: {
    editing: Boolean,
    error: { type: String, default: "" },
  },
  emits: ["save", "share"],
  template: `
    <div>
      <span class="save-mode">{{ editing ? "edit" : "create" }}</span>
      <p class="save-bar-error">{{ error }}</p>
      <button class="save-draft" @click="$emit('save')">Save draft</button>
      <button class="request-share" @click="$emit('share')">Share</button>
    </div>
  `,
});
const CustomerFieldsStub = defineComponent({
  props: { errors: { type: Object, default: undefined } },
  template: '<p class="customer-name-error">{{ errors?.customerName }}</p>',
});

describe("quote share controls", () => {
  it("keeps copy and WhatsApp as explicit user-selected actions", async () => {
    const wrapper = mount(QuoteBuilder, {
      props: {
        initialQuote: quote,
        professional,
        savingIntent: null,
        saveError: "",
        sharingMethod: null,
        shareError: "",
        shareEnabled: true,
      },
      global: {
        stubs: {
          DashboardQuoteCustomerFields: true,
          DashboardQuoteServiceFields: true,
          DashboardQuoteChangeRequests: true,
          DashboardQuoteLineItemsEditor: true,
          DashboardQuoteNotesField: true,
          DashboardQuoteSaveBar: true,
          QuotesQuotePreview: true,
          UModal: ModalStub,
          UButton: ButtonStub,
          DesignSystemDisabledTooltip: TooltipStub,
          UIcon: true,
        },
      },
    });
    const buttons = wrapper.findAll("button");
    const copy = buttons.find((button) => button.text() === "Copiar link");
    const whatsapp = buttons.find(
      (button) => button.text() === "Abrir WhatsApp",
    );

    await copy?.trigger("click");
    await whatsapp?.trigger("click");

    expect(wrapper.emitted("share")).toEqual([["copy"], ["whatsapp"]]);
    expect(wrapper.find(".quote-builder__revoke").exists()).toBe(false);

    await wrapper.setProps({ sharingMethod: "copy" });
    expect(copy?.attributes("disabled")).toBeDefined();
    expect(whatsapp?.attributes("disabled")).toBeDefined();
    expect(
      copy?.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde a cópia do link do orçamento terminar.");
    expect(
      whatsapp?.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde a cópia do link do orçamento terminar.");
  });

  it("asks for confirmation before revoking a shared link", async () => {
    const wrapper = mount(QuoteBuilder, {
      props: {
        initialQuote: {
          ...quote,
          status: "shared",
          sharedAt: "2026-08-18T13:00:00Z",
        },
        professional,
        savingIntent: null,
        saveError: "",
        sharingMethod: null,
        shareError: "",
        shareEnabled: true,
      },
      global: {
        stubs: {
          DashboardQuoteCustomerFields: true,
          DashboardQuoteServiceFields: true,
          DashboardQuoteChangeRequests: true,
          DashboardQuoteLineItemsEditor: true,
          DashboardQuoteNotesField: true,
          DashboardQuoteSaveBar: true,
          QuotesQuotePreview: true,
          UModal: ModalStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    const panel = wrapper.find(".quote-builder__revoke");
    expect(panel.exists()).toBe(true);

    // Opening the panel action only asks for confirmation.
    await panel.get("button").trigger("click");
    expect(wrapper.emitted("revoke")).toBeUndefined();

    const confirm = wrapper
      .findAll("button")
      .filter(
        (button) =>
          button.text() === "Revogar link" &&
          !panel.element.contains(button.element),
      );
    expect(confirm).toHaveLength(1);
    await confirm[0]!.trigger("click");
    expect(wrapper.emitted("revoke")).toHaveLength(1);
  });

  it("saves a new or edited quote before opening share options", async () => {
    const draft = { ...quote, id: null, number: null };
    const wrapper = mount(QuoteBuilder, {
      props: {
        initialQuote: draft,
        professional,
        savingIntent: null,
        saveError: "",
        sharingMethod: null,
        shareError: "",
        shareEnabled: true,
      },
      global: {
        stubs: {
          DashboardQuoteCustomerFields: true,
          DashboardQuoteServiceFields: true,
          DashboardQuoteChangeRequests: true,
          DashboardQuoteLineItemsEditor: true,
          DashboardQuoteNotesField: true,
          DashboardQuoteSaveBar: SaveBarStub,
          QuotesQuotePreview: true,
          UModal: ModalStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    await wrapper.get(".request-share").trigger("click");

    expect(wrapper.get(".save-mode").text()).toBe("create");
    expect(wrapper.emitted("prepareShare")?.[0]?.[0]).toMatchObject({
      id: null,
      customerName: quote.customerName,
      status: "saved",
    });
    expect(wrapper.emitted("update:shareOpen")).toBeUndefined();
  });

  it("promotes a persisted draft to saved before opening share options", async () => {
    const wrapper = mount(QuoteBuilder, {
      props: {
        initialQuote: quote,
        professional,
        shareOpen: false,
        savingIntent: null,
        saveError: "",
        sharingMethod: null,
        shareError: "",
        shareEnabled: true,
      },
      global: {
        stubs: {
          DashboardQuoteCustomerFields: true,
          DashboardQuoteServiceFields: true,
          DashboardQuoteChangeRequests: true,
          DashboardQuoteLineItemsEditor: true,
          DashboardQuoteNotesField: true,
          DashboardQuoteSaveBar: SaveBarStub,
          QuotesQuotePreview: true,
          UModal: ModalStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    await wrapper.get(".request-share").trigger("click");

    expect(wrapper.get(".save-mode").text()).toBe("edit");
    expect(wrapper.emitted("prepareShare")?.[0]?.[0]).toMatchObject({
      id: quote.id,
      status: "saved",
    });
    expect(wrapper.emitted("update:shareOpen")).toBeUndefined();
  });

  it("opens share options immediately for an unchanged saved quote", async () => {
    const wrapper = mount(QuoteBuilder, {
      props: {
        initialQuote: { ...quote, status: "saved" },
        professional,
        shareOpen: false,
        savingIntent: null,
        saveError: "",
        sharingMethod: null,
        shareError: "",
        shareEnabled: true,
      },
      global: {
        stubs: {
          DashboardQuoteCustomerFields: true,
          DashboardQuoteServiceFields: true,
          DashboardQuoteChangeRequests: true,
          DashboardQuoteLineItemsEditor: true,
          DashboardQuoteNotesField: true,
          DashboardQuoteSaveBar: SaveBarStub,
          QuotesQuotePreview: true,
          UModal: ModalStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    await wrapper.get(".request-share").trigger("click");

    expect(wrapper.emitted("prepareShare")).toBeUndefined();
    expect(wrapper.emitted("update:shareOpen")).toEqual([[true]]);
  });

  it("reveals inline errors and blocks invalid submissions", async () => {
    const wrapper = mount(QuoteBuilder, {
      props: {
        initialQuote: {
          ...quote,
          id: null,
          number: null,
          customerName: "",
          validUntil: "",
        },
        professional,
        savingIntent: null,
        saveError: "",
        sharingMethod: null,
        shareError: "",
        shareEnabled: true,
      },
      global: {
        stubs: {
          DashboardQuoteCustomerFields: CustomerFieldsStub,
          DashboardQuoteServiceFields: true,
          DashboardQuoteChangeRequests: true,
          DashboardQuoteLineItemsEditor: true,
          DashboardQuoteNotesField: true,
          DashboardQuoteSaveBar: SaveBarStub,
          QuotesQuotePreview: true,
          UModal: ModalStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    expect(wrapper.get(".customer-name-error").text()).toBe("");
    await wrapper.get(".request-share").trigger("click");

    expect(wrapper.emitted("prepareShare")).toBeUndefined();
    expect(wrapper.emitted("update:shareOpen")).toBeUndefined();
    expect(wrapper.get(".customer-name-error").text()).toBe(
      "Informe o nome do cliente.",
    );
    expect(wrapper.get(".save-bar-error").text()).toBe(
      "Revise os campos destacados para continuar.",
    );
  });

  it("allows an incomplete quote to be saved as a draft", async () => {
    const wrapper = mount(QuoteBuilder, {
      props: {
        initialQuote: {
          ...quote,
          id: null,
          number: null,
          customerName: "",
          customerPhone: "",
          serviceDescription: "",
          validUntil: "",
          items: [{ ...quote.items[0]!, description: "" }],
        },
        professional,
        savingIntent: null,
        saveError: "",
        sharingMethod: null,
        shareError: "",
        shareEnabled: true,
      },
      global: {
        stubs: {
          DashboardQuoteCustomerFields: CustomerFieldsStub,
          DashboardQuoteServiceFields: true,
          DashboardQuoteChangeRequests: true,
          DashboardQuoteLineItemsEditor: true,
          DashboardQuoteNotesField: true,
          DashboardQuoteSaveBar: SaveBarStub,
          QuotesQuotePreview: true,
          UModal: ModalStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    await wrapper.get(".save-draft").trigger("click");

    expect(wrapper.emitted("save")?.[0]?.[0]).toMatchObject({
      status: "draft",
      customerName: "",
      serviceDescription: "",
    });
    expect(wrapper.get(".customer-name-error").text()).toBe("");
  });

  it.each([
    ["approved", "Orçamento aprovado"],
    ["completed", "Orçamento concluído"],
    ["cancelled", "Orçamento cancelado"],
  ] as const)("keeps a %s quote read-only", (status, title) => {
    const wrapper = mount(QuoteBuilder, {
      props: {
        initialQuote: {
          ...quote,
          status,
          serviceJob: {
            id: "7a2ffba8-2e04-4237-94e6-3bc06c2de888",
            status:
              status === "cancelled"
                ? "cancelled"
                : status === "completed"
                  ? "completed"
                  : "approved",
            completedAt: status === "completed" ? "2026-08-29T15:00:00Z" : null,
            cancelledAt: status === "cancelled" ? "2026-08-29T15:00:00Z" : null,
          },
        },
        professional,
        savingIntent: null,
        saveError: "",
        sharingMethod: null,
        shareError: "",
        shareEnabled: false,
      },
      global: {
        stubs: {
          DashboardQuoteCustomerFields: true,
          DashboardQuoteServiceFields: true,
          DashboardQuoteChangeRequests: true,
          DashboardQuoteLineItemsEditor: true,
          DashboardQuoteNotesField: true,
          DashboardQuoteSaveBar: SaveBarStub,
          QuotesQuotePreview: true,
          UModal: ModalStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    expect(wrapper.get(".quote-builder__locked").text()).toContain(title);
    expect(wrapper.find(".save-draft").exists()).toBe(false);
    expect(wrapper.find(".quote-builder__revoke").exists()).toBe(false);
  });
});
