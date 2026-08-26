import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import SearchAuditDetailsModal from "@app/components/admin/search-audits/SearchAuditDetailsModal.vue";
import SearchAuditList from "@app/components/admin/search-audits/SearchAuditList.vue";
import SearchAuditOverview from "@app/components/admin/search-audits/SearchAuditOverview.vue";
import type { SearchAuditItem, SearchAuditPage } from "@app/types";

const UButtonStub = defineComponent({
  props: {
    label: { type: String, default: "" },
    disabled: { type: Boolean, default: false },
  },
  emits: ["click"],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')"><slot>{{ label }}</slot></button>',
});

const UModalStub = defineComponent({
  template:
    '<section><slot name="body" /><footer><slot name="footer" /></footer></section>',
});

const UIconStub = defineComponent({ template: "<i />" });

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

const meta: SearchAuditPage["meta"] = {
  page: 1,
  perPage: 20,
  totalCount: 21,
  totalPages: 2,
};

describe("administrator search-audit table", () => {
  it("shows scan-first signals, escapes the prompt, and opens details", async () => {
    const thin = { ...completed, resultCount: 2 };
    const wrapper = mount(SearchAuditList, {
      props: { items: [thin], meta },
      global: { stubs: { UButton: UButtonStub } },
    });

    expect(wrapper.find("table").exists()).toBe(true);
    expect(wrapper.findAll("thead th").map((header) => header.text())).toEqual([
      "Busca",
      "Interpretação",
      "Localização",
      "Diagnóstico",
      "Resultados",
      "Quando",
      "Ações",
    ]);
    expect(wrapper.text()).toContain("Preciso de pintor");
    expect(wrapper.text()).toContain("Pintor");
    expect(wrapper.get(".audit-list__location").text()).toBe("Joinville - SC");
    expect(wrapper.text()).toContain("Poucos resultados");
    expect(wrapper.get(".audit-list__count").text()).toBe("2");
    expect(wrapper.find("img").exists()).toBe(false);
    const diagnostic = wrapper.get(".audit-list__diagnostic");
    expect(diagnostic.element.children[0]?.textContent).toBe("Concluída");
    expect(diagnostic.element.children[1]?.textContent?.trim()).toBe(
      "Poucos resultados",
    );

    await wrapper.get(".audit-list__action button").trigger("click");
    expect(wrapper.emitted("view")).toEqual([[thin]]);
    await wrapper.get(".audit-pagination button:last-child").trigger("click");
    expect(wrapper.emitted("changePage")).toEqual([[2]]);
  });

  it("classifies a pre-LLM rejection as an operational issue", () => {
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
      props: { items: [limited], meta: { ...meta, totalPages: 1 } },
      global: { stubs: { UButton: UButtonStub } },
    });

    expect(wrapper.text()).toContain("Falha operacional");
    expect(wrapper.text()).toContain("Limite da aplicação");
  });
});

describe("administrator search-audit details", () => {
  it("keeps full raw, parsed, normalized, and technical data in an escaped modal", () => {
    const wrapper = mount(SearchAuditDetailsModal, {
      props: { item: completed, open: true },
      global: { stubs: { UModal: UModalStub, UButton: UButtonStub } },
    });

    expect(wrapper.text()).toContain("Eu preciso de pintor no América");
    expect(wrapper.text()).toContain('<script>alert("x")</script>');
    expect(wrapper.text()).toContain('"normalizedRequest"');
    expect(wrapper.text()).toContain("req_123");
    expect(wrapper.find("script").exists()).toBe(false);
  });
});

describe("administrator search-audit overview", () => {
  it("filters by KPI, text, and explicit controls", async () => {
    const wrapper = mount(SearchAuditOverview, {
      props: {
        summary: {
          total: 20,
          zeroResults: 4,
          notUnderstood: 3,
          thinResults: 5,
          operationalIssue: 2,
          healthy: 6,
        },
        q: "",
        outcome: null,
        sort: "results_asc",
        isLoading: false,
      },
      global: { stubs: { UButton: UButtonStub, UIcon: UIconStub } },
    });

    const cards = wrapper.findAll(".audit-overview__card");
    expect(cards).toHaveLength(6);
    await cards[1]?.trigger("click");
    expect(wrapper.emitted("outcome")).toContainEqual(["zero_results"]);

    await wrapper.get("#audit-query").setValue("eletricista");
    await wrapper.get("form").trigger("submit");
    expect(wrapper.emitted("search")).toEqual([["eletricista"]]);

    await wrapper.get("#audit-sort").setValue("newest");
    expect(wrapper.emitted("sort")).toEqual([["newest"]]);
  });
});
