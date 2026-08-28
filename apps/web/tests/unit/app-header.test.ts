import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { defineComponent } from "vue";
import AppHeader from "~/components/AppHeader.vue";
import type { RestoredApplicationSession } from "~/services/api/application-session";

const mocks = vi.hoisted(() => ({
  readSession: vi.fn(),
}));

vi.mock("~/services/api/client", () => ({
  useApiClient: () => ({}),
}));
vi.mock("~/services/api/application-session", async (importOriginal) => ({
  ...(await importOriginal()),
  getCurrentApplicationSession: mocks.readSession,
}));

const NuxtLinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});
const UButtonStub = defineComponent({
  props: {
    label: { type: String, default: "" },
    to: { type: String, default: "" },
  },
  template: '<a v-if="to" :href="to">{{ label }}<slot /></a>',
});

async function mountHeader(route: string) {
  const path = route.split("?")[0] ?? route;
  if (
    path.startsWith("/app/professional") &&
    path !== "/app/professional/login"
  ) {
    mocks.readSession.mockResolvedValue(restoredProfessional(true, false));
  } else if (path.startsWith("/app/admin") && path !== "/app/admin/login") {
    mocks.readSession.mockResolvedValue(restoredAdmin());
  }

  const wrapper = await mountSuspended(AppHeader, {
    route,
    global: {
      stubs: {
        DesignSystemContainer: { template: "<div><slot /></div>" },
        DesignSystemBrand: { template: "<span>Berufe</span>" },
        NuxtLink: NuxtLinkStub,
        UButton: UButtonStub,
        UIcon: true,
        AuthSessionLogoutButton: {
          template: '<button class="logout-stub">Sair</button>',
        },
      },
    },
  });
  await flushPromises();
  return wrapper;
}

function restoredProfessional(
  registrationCompleted: boolean,
  onboardingCompleted: boolean,
): RestoredApplicationSession {
  return {
    account: {
      id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
      role: "professional",
      status: "active",
      registered: registrationCompleted,
      verified: true,
      registrationCompleted,
      onboardingCompleted,
      registrationDisplayName: "Ana Souza",
      professionalProfileId: registrationCompleted
        ? "fc34e59b-0915-45c1-b0ea-29015578264a"
        : null,
      relationshipEligible: false,
    },
    session: {
      authenticationMethod: "sms_otp",
      authenticatedAt: "2026-08-15T12:00:00.000Z",
      idleExpiresAt: "2026-08-15T12:30:00.000Z",
      absoluteExpiresAt: "2026-08-16T00:00:00.000Z",
    },
  };
}

function restoredAdmin(): RestoredApplicationSession {
  return {
    account: {
      id: "fab9823b-9099-4ed5-9619-fd8435e958a5",
      role: "admin",
      status: "active",
      registered: false,
      verified: false,
      registrationCompleted: false,
      onboardingCompleted: false,
      registrationDisplayName: null,
      professionalProfileId: null,
      relationshipEligible: false,
    },
    session: {
      authenticationMethod: "password",
      authenticatedAt: "2026-08-15T12:00:00.000Z",
      idleExpiresAt: "2026-08-15T12:30:00.000Z",
      absoluteExpiresAt: "2026-08-16T00:00:00.000Z",
    },
  };
}

beforeEach(() => {
  clearNuxtState();
  mocks.readSession.mockReset().mockResolvedValue(null);
});

describe("application header", () => {
  it("separates public information, login, and signup navigation", async () => {
    const wrapper = await mountHeader("/encontrar");

    expect(wrapper.text()).toContain("Buscar profissionais");
    expect(wrapper.text()).toContain("Como funciona");
    expect(wrapper.text()).toContain("Para profissionais");
    expect(wrapper.text()).not.toContain("Sou um profissional");
    expect(wrapper.text()).toContain("Entrar");
    expect(wrapper.text()).toContain("Criar perfil grátis");
    expect(wrapper.get('a[href="/#para-profissionais"]')).toBeDefined();
    expect(wrapper.findAll('a[href="/app/professional/login"]')).toHaveLength(
      2,
    );
    expect(
      wrapper.findAll('a[href="/app/professional/login?intent=signup"]'),
    ).toHaveLength(2);
    expect(wrapper.get(".header__mobile-login").text()).toBe("Entrar");
    expect(wrapper.get(".header__mobile-signup-button").text()).toBe(
      "Criar perfil grátis",
    );
    expect(wrapper.find(".logout-stub").exists()).toBe(false);
    expect(mocks.readSession).toHaveBeenCalledOnce();
  });

  it.each([
    [false, false, "Continuar cadastro", "/app/professional/login"],
    [true, false, "Ir ao painel", "/app/professional/onboarding"],
    [true, true, "Ir ao painel", "/app/professional"],
  ] as const)(
    "shows one contextual action for registration %s and onboarding %s",
    async (
      registrationCompleted,
      onboardingCompleted,
      expectedLabel,
      expectedPath,
    ) => {
      mocks.readSession.mockResolvedValue(
        restoredProfessional(registrationCompleted, onboardingCompleted),
      );

      const wrapper = await mountHeader("/encontrar");

      expect(wrapper.findAll(`a[href="${expectedPath}"]`)).toHaveLength(2);
      expect(wrapper.get(".header__desktop-auth").text()).toBe(expectedLabel);
      expect(wrapper.get(".header__mobile-login").text()).toBe(expectedLabel);
      expect(wrapper.text()).not.toContain("Criar perfil grátis");
      expect(wrapper.find(".header__mobile-signup").exists()).toBe(false);
    },
  );

  it("keeps visitor actions available when session restoration fails", async () => {
    mocks.readSession.mockRejectedValue(new Error("session unavailable"));

    const wrapper = await mountHeader("/encontrar");

    expect(wrapper.text()).toContain("Entrar");
    expect(wrapper.text()).toContain("Criar perfil grátis");
  });

  it("does not repeat public authentication actions on the auth page", async () => {
    const wrapper = await mountHeader("/app/professional/login?intent=signup");

    expect(wrapper.text()).toContain("Para profissionais");
    expect(wrapper.find(".header__desktop-auth").exists()).toBe(false);
    expect(wrapper.find(".header__mobile-login").exists()).toBe(false);
    expect(wrapper.find(".header__mobile-signup").exists()).toBe(false);
    expect(mocks.readSession).toHaveBeenCalledOnce();
  });

  it("renders the approved logout action in professional desktop and mobile navigation", async () => {
    const wrapper = await mountHeader("/app/professional/profile");

    expect(wrapper.classes()).toContain("header--workspace");
    expect(wrapper.text()).toContain("Visão geral");
    expect(wrapper.text()).toContain("Gerenciar");
    expect(wrapper.text()).toContain("Orçamentos");
    expect(wrapper.get('a[href="/app/professional/quotes"]')).toBeDefined();
    expect(wrapper.findAll(".logout-stub")).toHaveLength(1);

    const menu = wrapper.get(".header__menu");
    expect(menu.attributes("aria-label")).toBe("Abrir menu");
    await menu.trigger("click");
    expect(menu.attributes("aria-label")).toBe("Fechar menu");
    expect(wrapper.findAll(".logout-stub")).toHaveLength(2);
    await wrapper.get(".header__mobile-nav a").trigger("click");
    expect(wrapper.find(".header__mobile-nav").exists()).toBe(false);
  });

  it("keeps the quotes navigation active across list and editor routes", async () => {
    const wrapper = await mountHeader("/app/professional/quotes/new");

    expect(
      wrapper.get('a[href="/app/professional/quotes"]').classes(),
    ).toContain("header__link--active");
  });

  it("renders the same approved action without changing existing admin links", async () => {
    const wrapper = await mountHeader("/app/admin/catalog");

    expect(wrapper.text()).toContain("Moderação");
    expect(wrapper.text()).toContain("Catálogo");
    expect(wrapper.text()).toContain("Relatórios");
    expect(wrapper.text()).toContain("Auditoria de buscas");
    expect(wrapper.get('a[href="/app/admin/catalog"]').classes()).toContain(
      "header__link--active",
    );
    expect(wrapper.findAll(".logout-stub")).toHaveLength(1);
  });

  it("keeps the dedicated administrator login outside workspace navigation", async () => {
    const wrapper = await mountHeader("/app/admin/login");

    expect(wrapper.classes()).not.toContain("header--workspace");
    expect(wrapper.text()).not.toContain("Moderação");
    expect(wrapper.text()).not.toContain("Criar perfil grátis");
    expect(wrapper.find(".logout-stub").exists()).toBe(false);
  });
});
