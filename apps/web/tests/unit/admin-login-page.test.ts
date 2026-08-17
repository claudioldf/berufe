import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { ref, type Ref } from "vue";
import AdminLoginPage from "~/pages/app/admin/login.vue";

const mocks = vi.hoisted(() => ({
  replace: vi.fn(),
  restoreSession: vi.fn(),
  refreshSession: vi.fn(),
  login: vi.fn(),
  state: undefined as
    | {
        account: Ref<{ role: "professional" | "admin" } | null>;
        session: Ref<{
          authenticationMethod: "sms_otp" | "password";
        } | null>;
        email: Ref<string>;
        password: Ref<string>;
        isLoading: Ref<boolean>;
        error: Ref<string>;
      }
    | undefined,
}));

vi.mock("~/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({
    account: mocks.state!.account,
    session: mocks.state!.session,
    restoreSession: mocks.restoreSession,
    refreshSession: mocks.refreshSession,
  }),
}));
vi.mock("~/composables/useAdminAuthFlow", () => ({
  useAdminAuthFlow: () => ({
    email: mocks.state!.email,
    password: mocks.state!.password,
    isLoading: mocks.state!.isLoading,
    error: mocks.state!.error,
    login: mocks.login,
  }),
}));

beforeEach(() => {
  vi.restoreAllMocks();
  vi.clearAllMocks();
  mocks.state = {
    account: ref(null),
    session: ref(null),
    email: ref(""),
    password: ref(""),
    isLoading: ref(false),
    error: ref(""),
  };
  mocks.restoreSession.mockResolvedValue(false);
  mocks.refreshSession.mockResolvedValue(true);
  mocks.login.mockResolvedValue(true);
  vi.spyOn(useRouter(), "replace").mockImplementation(async (to) => {
    mocks.replace(to);
  });
});

async function mountPage() {
  const wrapper = await mountSuspended(AdminLoginPage, { shallow: true });
  await flushPromises();
  return wrapper;
}

describe("administrator login page", () => {
  it("restores an existing administrator password session", async () => {
    mocks.state!.account.value = { role: "admin" };
    mocks.state!.session.value = { authenticationMethod: "password" };
    mocks.restoreSession.mockResolvedValue(true);

    await mountPage();

    expect(mocks.replace).toHaveBeenCalledWith("/app/admin");
  });

  it("refreshes the Rails session before entering the administrator workspace", async () => {
    const wrapper = await mountPage();
    mocks.state!.account.value = { role: "admin" };
    mocks.state!.session.value = { authenticationMethod: "password" };

    await (
      wrapper.vm as unknown as { submitLogin: () => Promise<void> }
    ).submitLogin();

    expect(mocks.login).toHaveBeenCalledOnce();
    expect(mocks.refreshSession).toHaveBeenCalledOnce();
    expect(mocks.replace).toHaveBeenCalledWith("/app/admin");
  });

  it("does not enter the workspace with the wrong restored role or method", async () => {
    const wrapper = await mountPage();
    mocks.replace.mockClear();
    mocks.state!.account.value = { role: "professional" };
    mocks.state!.session.value = { authenticationMethod: "sms_otp" };

    await (
      wrapper.vm as unknown as { submitLogin: () => Promise<void> }
    ).submitLogin();

    expect(mocks.replace).not.toHaveBeenCalled();
    expect(mocks.state!.error.value).toBe(
      "Não foi possível confirmar sua sessão administrativa.",
    );
  });

  it("keeps safe login and restoration failures on the form", async () => {
    const wrapper = await mountPage();
    mocks.login.mockResolvedValueOnce(false);

    await (
      wrapper.vm as unknown as { submitLogin: () => Promise<void> }
    ).submitLogin();
    expect(mocks.refreshSession).not.toHaveBeenCalled();

    mocks.login.mockResolvedValueOnce(true);
    mocks.refreshSession.mockRejectedValueOnce(new Error("unavailable"));
    await (
      wrapper.vm as unknown as { submitLogin: () => Promise<void> }
    ).submitLogin();
    expect(mocks.state!.error.value).toContain(
      "Não foi possível confirmar sua sessão agora",
    );
  });
});
