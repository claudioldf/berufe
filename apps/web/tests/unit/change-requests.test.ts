import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import ChangeRequests from "~/components/dashboard/quote/ChangeRequests.vue";

const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});

describe("quote change requests", () => {
  it("renders every customer request as a dated, read-only history", () => {
    const wrapper = mount(ChangeRequests, {
      props: {
        requests: [
          {
            id: "newer-request",
            revision: 4,
            message: "Retirar o segundo ponto de luz.",
            requestedAt: "2026-08-18T15:30:00Z",
          },
          {
            id: "older-request",
            revision: 2,
            message: "Trocar uma luminária de lugar.",
            requestedAt: "2026-08-17T15:30:00Z",
          },
        ],
      },
      global: {
        stubs: {
          DesignSystemSurfaceCard: SurfaceCardStub,
          UIcon: true,
        },
      },
    });

    expect(wrapper.get("h2").text()).toBe("Solicitações de alteração");
    expect(wrapper.findAll("li").map((item) => item.text())).toEqual([
      expect.stringContaining("Retirar o segundo ponto de luz."),
      expect.stringContaining("Trocar uma luminária de lugar."),
    ]);
    expect(wrapper.findAll("time")[0]?.attributes("datetime")).toBe(
      "2026-08-18T15:30:00Z",
    );
  });
});
