import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import SearchAuditList from "@app/components/admin/search-audits/SearchAuditList.vue";
import type { SearchAuditItem } from "@app/types";

const UButtonStub = defineComponent({
  props: {
    label: { type: String, required: true },
    disabled: { type: Boolean, default: false },
  },
  emits: ["click"],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
});

const completed: SearchAuditItem = {
  id: "audit-1",
  inputPrompt: "<img src=x onerror=alert(1)> Preciso de pintor",
  rawLlmResponse: '<script>alert("x")</script>',
  parsedResponse: {
    serviceIds: ["service-1"],
    services: [{ id: "service-1", name: "Pintor" }],
    locations: [
      {
        stateCode: "SC",
        city: "Joinville",
        neighborhood: { code: "america", name: "América" },
      },
    ],
    keywords: [],
    normalizedRequest: "Eu preciso de pintor no América, Joinville.",
  },
  status: "completed",
  responseSource: "provider",
  adapter: "openai",
  model: "gpt-5-mini",
  providerRequestId: "req_123",
  promptDigest: "a".repeat(64),
  resultCount: 12,
  createdAt: "2026-08-25T12:00:00Z",
};

describe("administrator search-audit list", () => {
  it("renders escaped raw content and controlled interpretation", () => {
    const wrapper = mount(SearchAuditList, {
      props: {
        items: [completed],
        meta: { page: 1, perPage: 20, totalCount: 1, totalPages: 1 },
      },
      global: { stubs: { UButton: UButtonStub } },
    });

    expect(wrapper.text()).toContain("Preciso de pintor");
    expect(wrapper.text()).toContain("Pintor");
    expect(wrapper.text()).toContain("América, Joinville - SC");
    expect(wrapper.text()).toContain("Eu preciso de pintor no América");
    expect(wrapper.text()).toContain("12");
    expect(wrapper.find("img").exists()).toBe(false);
    expect(wrapper.find("script").exists()).toBe(false);
  });

  it("explains pre-LLM rejection and emits pagination choices", async () => {
    const limited: SearchAuditItem = {
      ...completed,
      id: "audit-2",
      rawLlmResponse: null,
      parsedResponse: null,
      status: "application_rate_limited",
      responseSource: null,
      resultCount: 0,
    };
    const wrapper = mount(SearchAuditList, {
      props: {
        items: [limited],
        meta: { page: 1, perPage: 20, totalCount: 21, totalPages: 2 },
      },
      global: { stubs: { UButton: UButtonStub } },
    });

    expect(wrapper.text()).toContain("Rejeitada antes do envio ao LLM.");
    expect(wrapper.text()).toContain("Limite da aplicação");
    await wrapper.get(".audit-pagination button:last-child").trigger("click");
    expect(wrapper.emitted("changePage")).toEqual([[2]]);
  });
});
