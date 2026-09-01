import { mount } from "@vue/test-utils";
import { mockNuxtImport } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import SessionLogoutButton from "~/components/auth/SessionLogoutButton.vue";

const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});
const global = {
  stubs: { DesignSystemDisabledTooltip: TooltipStub, UIcon: true },
};

const mocks = vi.hoisted(() => ({
  isEnding: { __v_isRef: true, value: false },
  logout: vi.fn(),
  clearSession: vi.fn(),
  setRole: vi.fn(),
  showToast: vi.fn(),
  navigateTo: vi.fn(),
}));

vi.mock("~/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({
    isEnding: mocks.isEnding,
    logout: mocks.logout,
    clearSession: mocks.clearSession,
  }),
}));
vi.mock("~/composables/useAppRole", () => ({
  useAppRole: () => ({ setRole: mocks.setRole }),
}));
vi.mock("~/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
}));
mockNuxtImport("navigateTo", () => mocks.navigateTo);

beforeEach(() => {
  mocks.isEnding.value = false;
  vi.clearAllMocks();
});

describe("session logout control", () => {
  it("revokes the session, resets the preview role, and returns to login", async () => {
    mocks.logout.mockResolvedValue(undefined);
    mocks.navigateTo.mockResolvedValue(undefined);
    const wrapper = mount(SessionLogoutButton, { global });

    await wrapper.get("button").trigger("click");

    expect(mocks.logout).toHaveBeenCalledOnce();
    expect(mocks.clearSession).toHaveBeenCalledOnce();
    expect(mocks.setRole).toHaveBeenCalledWith("visitor");
    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/professional/login", {
      replace: true,
    });
    expect(mocks.showToast).not.toHaveBeenCalled();
  });

  it("uses the existing toast surface when logout cannot be completed", async () => {
    mocks.logout.mockRejectedValue(new Error("private failure"));
    const wrapper = mount(SessionLogoutButton, { global });

    await wrapper.get("button").trigger("click");

    expect(mocks.clearSession).toHaveBeenCalledOnce();
    expect(mocks.setRole).toHaveBeenCalledWith("visitor");
    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/professional/login", {
      replace: true,
    });
    expect(mocks.showToast).toHaveBeenCalledWith({
      title: "Não foi possível sair",
      description: "Tente novamente em instantes.",
    });
  });

  it("navigates before a slow session revocation finishes", async () => {
    let resolveLogout: (() => void) | undefined;
    mocks.logout.mockReturnValue(
      new Promise<void>((resolve) => {
        resolveLogout = resolve;
      }),
    );
    mocks.navigateTo.mockResolvedValue(undefined);
    const wrapper = mount(SessionLogoutButton, { global });

    const click = wrapper.get("button").trigger("click");
    await Promise.resolve();
    await Promise.resolve();

    expect(mocks.clearSession).toHaveBeenCalledOnce();
    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/professional/login", {
      replace: true,
    });

    resolveLogout?.();
    await click;
    expect(mocks.showToast).not.toHaveBeenCalled();
  });

  it("renders its pending state as disabled", () => {
    mocks.isEnding.value = true;
    const wrapper = mount(SessionLogoutButton, { global });

    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
    expect(wrapper.text()).toContain("Saindo…");
    expect(
      wrapper
        .get("button")
        .element.closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde o encerramento da sessão terminar.");
  });
});
