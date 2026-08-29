import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import ProfessionalsPage from "~/pages/app/admin/professionals.vue";

const AdminWorkspaceStub = defineComponent({
  template: "<main><slot /></main>",
});

const ProfessionalsStub = defineComponent({
  name: "Professionals",
  template: "<p>Conteúdo dos profissionais carregado</p>",
});

describe("administrator professionals page", () => {
  it("mounts the professionals feature inside the workspace", async () => {
    const wrapper = await mountSuspended(ProfessionalsPage, {
      global: {
        stubs: {
          AdminWorkspace: AdminWorkspaceStub,
          Professionals: ProfessionalsStub,
        },
      },
    });

    expect(wrapper.text()).toContain("Conteúdo dos profissionais carregado");
  });
});
