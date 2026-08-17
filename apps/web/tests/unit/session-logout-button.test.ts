import { mount } from "@vue/test-utils";
import { mockNuxtImport } from "@nuxt/test-utils/runtime";
import SessionLogoutButton from "~/components/auth/SessionLogoutButton.vue";

const mocks = vi.hoisted(() => ({
  isEnding: { __v_isRef: true, value: false },
  logout: vi.fn(),
  setRole: vi.fn(),
  showToast: vi.fn(),
  navigateTo: vi.fn(),
}));

vi.mock("~/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({
    isEnding: mocks.isEnding,
    logout: mocks.logout,
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
    const wrapper = mount(SessionLogoutButton, {
      global: { stubs: { UIcon: true } },
    });

    await wrapper.get("button").trigger("click");

    expect(mocks.logout).toHaveBeenCalledOnce();
    expect(mocks.setRole).toHaveBeenCalledWith("visitor");
    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/professional/login", {
      replace: true,
    });
    expect(mocks.showToast).not.toHaveBeenCalled();
  });

  it("uses the existing toast surface when logout cannot be completed", async () => {
    mocks.logout.mockRejectedValue(new Error("private failure"));
    const wrapper = mount(SessionLogoutButton, {
      global: { stubs: { UIcon: true } },
    });

    await wrapper.get("button").trigger("click");

    expect(mocks.setRole).not.toHaveBeenCalled();
    expect(mocks.navigateTo).not.toHaveBeenCalled();
    expect(mocks.showToast).toHaveBeenCalledWith({
      title: "Não foi possível sair",
      description: "Tente novamente em instantes.",
    });
  });

  it("renders its pending state as disabled", () => {
    mocks.isEnding.value = true;
    const wrapper = mount(SessionLogoutButton, {
      global: { stubs: { UIcon: true } },
    });

    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
    expect(wrapper.text()).toContain("Saindo…");
  });
});
