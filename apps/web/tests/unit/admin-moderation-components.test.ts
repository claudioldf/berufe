import { mount } from "@vue/test-utils";
import ReviewPanel from "~/components/admin/moderation/ReviewPanel.vue";
import Toolbar from "~/components/admin/moderation/Toolbar.vue";
import type { ModerationQueueItem } from "~/types";

const verification: ModerationQueueItem = {
  id: "verification-id",
  targetType: "verification_request",
  status: "pending_review",
  type: "Verificação",
  title: "Verificação de identidade · Ana Souza",
  subtitle: "Eletricista · Toda Joinville",
  submittedAt: "17 de ago., 09:00",
  age: "há 3h",
  details: "Documento enviado para análise.",
  preview: "Documento privado",
  claimedBirthdate: "1990-04-12",
  verificationFileId: "verification-file-id",
};

describe("administrator moderation components", () => {
  it("renders the restricted identity document action and requires match confirmation", async () => {
    const wrapper = mount(ReviewPanel, {
      props: {
        item: verification,
        note: "",
      },
    });

    const preview = wrapper.get(".moderation__preview");
    expect(preview.text()).toContain("Documento enviado");
    expect(wrapper.text()).toContain("Acesso a arquivo restrito");
    function approveButton() {
      const button = wrapper
        .findAll("footer button")
        .find((candidate) => candidate.text().includes("Aprovar identidade"));
      if (!button) throw new Error("approve button not found");
      return button;
    }
    expect(approveButton().attributes("disabled")).toBeDefined();

    await wrapper.get('textarea[name="moderation-note"]').setValue("Conferida");
    expect(wrapper.emitted("note")?.at(-1)).toEqual(["Conferida"]);
    await wrapper.get('input[type="checkbox"]').setValue(true);
    expect(wrapper.emitted("identityMatch")?.at(-1)).toEqual([true]);
    await wrapper.setProps({ identityMatchConfirmed: true });
    await approveButton().trigger("click");
    expect(wrapper.emitted("approve")).toHaveLength(1);
  });

  it("keeps status and search as explicit server-filter events", async () => {
    const wrapper = mount(Toolbar, {
      props: {
        statusFilter: "pending_review",
        search: "",
      },
    });

    await wrapper.get("select").setValue("approved");
    expect(wrapper.emitted("status")?.at(-1)).toEqual(["approved"]);

    await wrapper.get('input[type="search"]').setValue("Ana");
    expect(wrapper.emitted("search")?.at(-1)).toEqual(["Ana"]);
  });

  it("emits the existing restricted-document action for verification work", async () => {
    const wrapper = mount(ReviewPanel, {
      props: { item: verification, note: "" },
    });

    await wrapper.get(".moderation__private-warning button").trigger("click");
    expect(wrapper.emitted("openEvidence")).toHaveLength(1);
  });

  it("renders reviewed work as read-only and disables missing evidence", () => {
    const wrapper = mount(ReviewPanel, {
      props: {
        item: {
          ...verification,
          status: "approved",
          verificationFileId: null,
        },
        note: "",
      },
    });

    expect(wrapper.find('input[type="checkbox"]').exists()).toBe(false);
    expect(wrapper.find('textarea[name="moderation-note"]').exists()).toBe(
      false,
    );
    expect(wrapper.find("footer").exists()).toBe(false);
    const evidenceButton = wrapper.get(".moderation__private-warning button");
    expect(evidenceButton.text()).toContain("Documento indisponível");
    expect(evidenceButton.attributes("disabled")).toBeDefined();
  });
});
