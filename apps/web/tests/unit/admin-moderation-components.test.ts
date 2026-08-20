import { mount } from "@vue/test-utils";
import ReviewPanel from "~/components/admin/moderation/ReviewPanel.vue";
import Toolbar from "~/components/admin/moderation/Toolbar.vue";
import type { ModerationQueueItem } from "~/types";

const photo: ModerationQueueItem = {
  id: "photo-id",
  targetType: "profile_photo",
  status: "pending_review",
  type: "Foto",
  title: "Foto de perfil · Ana Souza",
  subtitle: "Eletricista · Toda Joinville",
  submittedAt: "17 de ago., 09:00",
  age: "há 3h",
  details: "Foto enviada para análise.",
  preview: "Imagem privada",
  currentlyPublic: true,
  fallbackAvailable: true,
  changes: [],
  claimedBirthdate: null,
  hasMedia: true,
  verificationFileId: null,
};

describe("administrator moderation components", () => {
  it("renders regenerated private media inside the existing submitted-content block", async () => {
    const wrapper = mount(ReviewPanel, {
      props: {
        item: photo,
        note: "",
        mediaUrl: "blob:moderation-preview",
      },
    });

    const preview = wrapper.get(".moderation__preview");
    expect(preview.text()).toContain("Conteúdo enviado");
    expect(preview.get("img").attributes()).toMatchObject({
      src: "blob:moderation-preview",
      alt: "Conteúdo enviado para análise: Foto de perfil · Ana Souza",
    });

    await wrapper.get('textarea[name="moderation-note"]').setValue("Conferida");
    expect(wrapper.emitted("note")?.at(-1)).toEqual(["Conferida"]);
    await wrapper.get("footer button:last-child").trigger("click");
    expect(wrapper.emitted("approve")).toHaveLength(1);
  });

  it("keeps type, status, and search as explicit server-filter events", async () => {
    const wrapper = mount(Toolbar, {
      props: {
        typeFilter: "all",
        statusFilter: "pending_review",
        search: "",
      },
    });

    await wrapper
      .get(".moderation__filters button:nth-child(4)")
      .trigger("click");
    expect(wrapper.emitted("type")?.at(-1)).toEqual(["portfolio_item"]);

    await wrapper.get("select").setValue("approved");
    expect(wrapper.emitted("status")?.at(-1)).toEqual(["approved"]);

    await wrapper.get('input[type="search"]').setValue("Ana");
    expect(wrapper.emitted("search")?.at(-1)).toEqual(["Ana"]);
  });

  it("emits the existing restricted-document action for verification work", async () => {
    const verification: ModerationQueueItem = {
      ...photo,
      targetType: "verification_request",
      type: "Verificação",
      hasMedia: false,
      verificationFileId: "verification-file-id",
    };
    const wrapper = mount(ReviewPanel, {
      props: { item: verification, note: "" },
    });

    await wrapper.get(".moderation__private-warning button").trigger("click");
    expect(wrapper.emitted("openEvidence")).toHaveLength(1);
  });
});
