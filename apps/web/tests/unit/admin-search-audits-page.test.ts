import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import SearchAuditsPage from "~/pages/app/admin/search-audits.vue";

const AdminWorkspaceStub = defineComponent({
  template: "<main><slot /></main>",
});

const SearchAuditsStub = defineComponent({
  name: "SearchAudits",
  template: "<p>Conteúdo da auditoria carregado</p>",
});

describe("administrator search-audit page", () => {
  it("mounts the search-audit feature inside the workspace", async () => {
    const wrapper = await mountSuspended(SearchAuditsPage, {
      global: {
        stubs: {
          AdminWorkspace: AdminWorkspaceStub,
          SearchAudits: SearchAuditsStub,
        },
      },
    });

    expect(wrapper.text()).toContain("Conteúdo da auditoria carregado");
  });
});
