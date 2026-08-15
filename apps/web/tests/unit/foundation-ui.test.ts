import { mountSuspended } from "@nuxt/test-utils/runtime";
import { describe, expect, it } from "vitest";
import ApiStatusCard from "~/components/foundation/ApiStatusCard.vue";
import FeedbackForm from "~/components/foundation/FeedbackForm.vue";
import StateGallery from "~/components/foundation/StateGallery.vue";

describe("UI foundation", () => {
  it("shows API success and exposes recovery from an API error", async () => {
    const success = await mountSuspended(ApiStatusCard, {
      props: {
        status: "success",
        service: "berufe-api",
        serviceStatus: "ok",
      },
    });

    expect(success.get('[role="status"]').text()).toContain("berufe-api: ok");

    const failure = await mountSuspended(ApiStatusCard, {
      props: {
        status: "error",
        errorMessage: "Não foi possível concluir a solicitação.",
      },
    });
    await failure.get("button").trigger("click");

    expect(failure.get('[role="alert"]').text()).toContain(
      "Não foi possível concluir",
    );
    expect(failure.emitted("retry")).toHaveLength(1);
  });

  it("keeps invalid feedback local and emits a trimmed valid payload", async () => {
    const wrapper = await mountSuspended(FeedbackForm);

    await wrapper.get("form").trigger("submit");
    expect(wrapper.get('[role="alert"]').text()).toContain("nome completo");
    expect(wrapper.emitted("submitted")).toBeUndefined();

    await wrapper.get("input").setValue("  Ana Souza  ");
    await wrapper.get("textarea").setValue("  Interface clara.  ");
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("submitted")?.[0]?.[0]).toEqual({
      name: "Ana Souza",
      note: "Interface clara.",
    });
  });

  it("renders loading, empty, and error states with next actions", async () => {
    const wrapper = await mountSuspended(StateGallery);

    expect(wrapper.get('[aria-label="Carregando conteúdo"]')).toBeTruthy();
    expect(wrapper.text()).toContain("Nenhum item ainda");
    expect(wrapper.get('article[role="alert"]').text()).toContain(
      "Não foi possível carregar",
    );

    const buttons = wrapper.findAll("button");
    await buttons[0]?.trigger("click");
    await buttons[1]?.trigger("click");
    expect(wrapper.emitted("create")).toHaveLength(1);
    expect(wrapper.emitted("retry")).toHaveLength(1);
  });
});
