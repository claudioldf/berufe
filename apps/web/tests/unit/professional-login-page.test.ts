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
  changePhone: vi.fn(),
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
        step: Ref<number>;
        phone: Ref<string>;
        code: Ref<string>;
        name: Ref<string>;
        accepted: Ref<boolean>;
        isLoading: Ref<boolean>;
        error: Ref<string>;
        cooldown: Ref<number>;
      }
    | undefined,
}));

vi.mock("~/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({
    account: mocks.state!.account,
    restoreSession: mocks.restoreSession,
    refreshSession: mocks.refreshSession,
  }),
}));
vi.mock("~/composables/useAppRole", () => ({
  useAppRole: () => ({ setRole: mocks.setRole }),
}));
vi.mock("~/composables/usePhoneAuthFlow", () => ({
  usePhoneAuthFlow: () => ({
    step: mocks.state!.step,
    phone: mocks.state!.phone,
    code: mocks.state!.code,
    name: mocks.state!.name,
    accepted: mocks.state!.accepted,
    isLoading: mocks.state!.isLoading,
    error: mocks.state!.error,
    cooldown: mocks.state!.cooldown,
    requestCode: mocks.requestCode,
    verifyCode: mocks.verifyCode,
    changePhone: mocks.changePhone,
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
    step: ref(1),
    phone: ref("(47) 99999-1111"),
    code: ref(""),
    name: ref("Ana Reparos"),
    accepted: ref(true),
    isLoading: ref(false),
    error: ref(""),
    cooldown: ref(0),
  };
  mocks.restoreSession.mockResolvedValue(false);
  mocks.refreshSession.mockResolvedValue(true);
  mocks.registerProfessional.mockResolvedValue(true);
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
          phoneStepContent: { title: string; submitLabel: string };
        }
      ).phoneStepContent,
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

  it("keeps a signed-in professional in the forced SMS reauthentication flow", async () => {
    mocks.state!.account.value = {
      role: "professional",
      registrationCompleted: true,
      onboardingCompleted: true,
    };
    mocks.restoreSession.mockResolvedValue(true);
    mocks.verifyCode.mockImplementation(async () => {
      mocks.state!.step.value = 3;
    });

    const wrapper = await mountPage(
      "/app/professional/login?intent=reauthentication",
    );

    expect(mocks.replace).not.toHaveBeenCalledWith("/app/professional");
    expect(mocks.replace).not.toHaveBeenCalledWith("/app/professional/account");
    mocks.replace.mockClear();
    expect(
      (
        wrapper.vm as unknown as {
          phoneStepContent: { title: string };
        }
      ).phoneStepContent.title,
    ).toBe("Confirme seu telefone.");

    await (
      wrapper.vm as unknown as { confirmCode: () => Promise<void> }
    ).confirmCode();
    expect(mocks.replace).toHaveBeenCalledWith("/app/professional/account");
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
    mocks.verifyCode.mockImplementation(async () => {
      mocks.state!.step.value = 3;
    });
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
});
