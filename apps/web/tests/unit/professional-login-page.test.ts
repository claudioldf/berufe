import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { ref } from "vue";
import type { Ref } from "vue";
import ProfessionalLoginPage from "~/pages/app/professional/login.vue";

const mocks = vi.hoisted(() => ({
  replace: vi.fn(),
  restoreSession: vi.fn(),
  refreshSession: vi.fn(),
  initializeFromAuth: vi.fn(),
  setRole: vi.fn(),
  showToast: vi.fn(),
  requestCode: vi.fn(),
  verifyCode: vi.fn(),
  changeDestination: vi.fn(),
  resumeRegistration: vi.fn(),
  registerProfessional: vi.fn(),
  state: undefined as
    | {
        account: Ref<{
          role: "professional" | "admin";
          registrationCompleted: boolean;
          onboardingCompleted: boolean;
          registrationDisplayName?: string | null;
        } | null>;
        session: Ref<{
          authenticationMethod: "sms_otp" | "email_otp" | "password";
        } | null>;
        step: Ref<number>;
        method: Ref<"phone" | "email">;
        phone: Ref<string>;
        email: Ref<string>;
        destination: Ref<string>;
        code: Ref<string>;
        name: Ref<string>;
        accepted: Ref<boolean>;
        isLoading: Ref<boolean>;
        error: Ref<string>;
        registrationFieldErrors: Ref<Record<string, string[]>>;
        cooldown: Ref<number>;
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
vi.mock("~/composables/useAppRole", () => ({
  useAppRole: () => ({ setRole: mocks.setRole }),
}));
vi.mock("~/composables/useProfessionalAuthFlow", () => ({
  useProfessionalAuthFlow: () => ({
    step: mocks.state!.step,
    method: mocks.state!.method,
    phone: mocks.state!.phone,
    email: mocks.state!.email,
    destination: mocks.state!.destination,
    code: mocks.state!.code,
    name: mocks.state!.name,
    accepted: mocks.state!.accepted,
    isLoading: mocks.state!.isLoading,
    error: mocks.state!.error,
    registrationFieldErrors: mocks.state!.registrationFieldErrors,
    cooldown: mocks.state!.cooldown,
    requestCode: mocks.requestCode,
    verifyCode: mocks.verifyCode,
    changeDestination: mocks.changeDestination,
    resumeRegistration: mocks.resumeRegistration,
    registerProfessional: mocks.registerProfessional,
  }),
}));
vi.mock("~/composables/useProfessionalOnboarding", () => ({
  useProfessionalOnboarding: () => ({
    initializeFromAuth: mocks.initializeFromAuth,
  }),
}));
vi.mock("~/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
}));

beforeEach(() => {
  vi.restoreAllMocks();
  vi.clearAllMocks();
  mocks.state = {
    account: ref(null),
    session: ref(null),
    step: ref(1),
    method: ref<"phone" | "email">("phone"),
    phone: ref("(47) 99999-1111"),
    email: ref(""),
    destination: ref("(47) 99999-1111"),
    code: ref(""),
    name: ref("Ana Reparos"),
    accepted: ref(true),
    isLoading: ref(false),
    error: ref(""),
    registrationFieldErrors: ref({}),
    cooldown: ref(0),
  };
  mocks.restoreSession.mockResolvedValue(false);
  mocks.refreshSession.mockResolvedValue(true);
  mocks.verifyCode.mockResolvedValue(false);
  mocks.registerProfessional.mockResolvedValue(true);
  mocks.resumeRegistration.mockImplementation(() => {
    mocks.state!.step.value = 3;
  });
  vi.spyOn(useRouter(), "replace").mockImplementation(async (to) => {
    mocks.replace(to);
  });
});

async function mountPage(route = "/app/professional/login") {
  await useRouter().push(route);
  const wrapper = await mountSuspended(ProfessionalLoginPage, {
    route,
    shallow: true,
  });
  await flushPromises();
  return wrapper;
}

describe("professional login page", () => {
  it("derives the professional entry experience from the URL intent", async () => {
    const signupWrapper = await mountPage(
      "/app/professional/login?intent=signup",
    );
    expect(
      (
        signupWrapper.vm as unknown as {
          contactStepContent: { title: string; submitLabel: string };
        }
      ).contactStepContent,
    ).toMatchObject({
      title: "Crie seu perfil profissional.",
      submitLabel: "Receber código e começar",
    });
  });

  it("sends a returning registered professional directly to setup", async () => {
    mocks.state!.account.value = {
      role: "professional",
      registrationCompleted: true,
      onboardingCompleted: false,
    };
    mocks.restoreSession.mockResolvedValue(true);

    await mountPage();

    expect(mocks.resumeRegistration).not.toHaveBeenCalled();
    expect(mocks.replace).toHaveBeenCalledWith("/app/professional/onboarding");
  });

  it("sends a returning professional with completed onboarding to the dashboard", async () => {
    mocks.state!.account.value = {
      role: "professional",
      registrationCompleted: true,
      onboardingCompleted: true,
    };
    mocks.restoreSession.mockResolvedValue(true);

    await mountPage();

    expect(mocks.resumeRegistration).not.toHaveBeenCalled();
    expect(mocks.replace).toHaveBeenCalledWith("/app/professional");
  });

  it("resumes the existing final step for an incomplete professional", async () => {
    mocks.state!.account.value = {
      role: "professional",
      registrationCompleted: false,
      onboardingCompleted: false,
      registrationDisplayName: "Carla Pinturas",
    };
    mocks.restoreSession.mockResolvedValue(true);

    await mountPage();

    expect(mocks.resumeRegistration).toHaveBeenCalledOnce();
    expect(mocks.state!.name.value).toBe("Carla Pinturas");
    expect(mocks.replace).not.toHaveBeenCalledWith(
      "/app/professional/onboarding",
    );
  });

  it("refreshes after OTP and registration before entering the workspace", async () => {
    mocks.verifyCode.mockResolvedValue(true);
    mocks.refreshSession
      .mockImplementationOnce(async () => {
        mocks.state!.account.value = {
          role: "professional",
          registrationCompleted: false,
          onboardingCompleted: false,
        };
        return true;
      })
      .mockImplementationOnce(async () => {
        mocks.state!.account.value = {
          role: "professional",
          registrationCompleted: true,
          onboardingCompleted: false,
        };
        return true;
      });
    const wrapper = await mountPage();

    await (
      wrapper.vm as unknown as { confirmCode: () => Promise<void> }
    ).confirmCode();
    expect(mocks.resumeRegistration).toHaveBeenCalledOnce();
    expect(mocks.replace).not.toHaveBeenCalledWith(
      "/app/professional/onboarding",
    );

    await (
      wrapper.vm as unknown as { register: () => Promise<void> }
    ).register();
    expect(mocks.registerProfessional).toHaveBeenCalledOnce();
    expect(mocks.initializeFromAuth).toHaveBeenCalledWith({
      name: "Ana Reparos",
      phone: "(47) 99999-1111",
    });
    expect(mocks.setRole).toHaveBeenCalledWith("professional");
    expect(mocks.replace).toHaveBeenCalledWith("/app/professional/onboarding");
  });

  it("starts email-authenticated onboarding with the complementary phone", async () => {
    mocks.state!.method.value = "email";
    mocks.state!.email.value = "ana@example.com";
    mocks.state!.phone.value = "(47) 9 9999-2222";
    const wrapper = await mountPage();

    await (
      wrapper.vm as unknown as { register: () => Promise<void> }
    ).register();

    expect(mocks.initializeFromAuth).toHaveBeenCalledWith({
      name: "Ana Reparos",
      phone: "(47) 9 9999-2222",
    });
  });

  it("restores the complementary field from the session authentication method", async () => {
    mocks.state!.account.value = {
      role: "professional",
      registrationCompleted: false,
      onboardingCompleted: false,
    };
    mocks.state!.session.value = { authenticationMethod: "email_otp" };
    mocks.restoreSession.mockResolvedValue(true);

    await mountPage();

    expect(mocks.state!.method.value).toBe("email");
    expect(mocks.resumeRegistration).toHaveBeenCalledOnce();
  });

  it("keeps the OTP step visible until a returning account is resolved", async () => {
    mocks.state!.step.value = 2;
    mocks.verifyCode.mockResolvedValue(true);
    let resolveRefresh: (() => void) | undefined;
    mocks.refreshSession.mockImplementationOnce(
      () =>
        new Promise<boolean>((resolve) => {
          resolveRefresh = () => {
            mocks.state!.account.value = {
              role: "professional",
              registrationCompleted: true,
              onboardingCompleted: true,
            };
            resolve(true);
          };
        }),
    );
    const wrapper = await mountPage();

    const confirmation = (
      wrapper.vm as unknown as { confirmCode: () => Promise<void> }
    ).confirmCode();
    await flushPromises();

    expect(mocks.refreshSession).toHaveBeenCalledOnce();
    expect(wrapper.find("auth-code-step-stub").exists()).toBe(true);
    expect(wrapper.find("auth-registration-step-stub").exists()).toBe(false);
    expect(mocks.resumeRegistration).not.toHaveBeenCalled();

    resolveRefresh?.();
    await confirmation;

    expect(mocks.resumeRegistration).not.toHaveBeenCalled();
    expect(mocks.replace).toHaveBeenCalledWith("/app/professional");
  });
});
