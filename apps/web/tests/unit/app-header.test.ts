import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import AppHeader from "~/components/AppHeader.vue";
import type {
  CurrentAccount,
  CurrentSession,
} from "~/services/api/application-session";

const NuxtLinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});
const UButtonStub = defineComponent({
  props: { label: { type: String, default: "" } },
  template: "<button>{{ label }}<slot /></button>",
});

async function mountHeader(route: string) {
  if (
    route.startsWith("/app/admin") ||
    (route.startsWith("/app/professional") &&
      route !== "/app/professional/login")
  ) {
    const role = route.startsWith("/app/admin") ? "admin" : "professional";
    useState("application-session-status", () => "authenticated").value =
      "authenticated";
    useState<CurrentAccount | null>(
      "application-session-account",
      () => null,
    ).value = {
      id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
      role,
      status: "active",
      registrationCompleted: true,
    };
    useState<CurrentSession | null>(
      "application-session-summary",
      () => null,
    ).value = {
      authenticationMethod: role === "admin" ? "password" : "sms_otp",
      authenticatedAt: "2026-08-15T12:00:00.000Z",
      idleExpiresAt: "2026-08-15T12:30:00.000Z",
      absoluteExpiresAt: "2026-08-16T00:00:00.000Z",
    };
  }

  return mountSuspended(AppHeader, {
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
}

beforeEach(() => {
  clearNuxtState();
});

describe("application header", () => {
  it("keeps the existing public navigation without a logout action", async () => {
    const wrapper = await mountHeader("/encontrar");

    expect(wrapper.text()).toContain("Encontrar profissional");
    expect(wrapper.text()).toContain("Como funciona");
    expect(wrapper.text()).toContain("Para profissionais");
    expect(wrapper.text()).toContain("Entrar");
    expect(wrapper.find(".logout-stub").exists()).toBe(false);
  });

  it("renders the approved logout action in professional desktop and mobile navigation", async () => {
    const wrapper = await mountHeader("/app/professional/profile");

    expect(wrapper.classes()).toContain("header--workspace");
    expect(wrapper.text()).toContain("Visão geral");
    expect(wrapper.text()).toContain("Meu perfil");
    expect(wrapper.text()).toContain("Orçamentos");
    expect(wrapper.findAll(".logout-stub")).toHaveLength(1);

    const menu = wrapper.get(".header__menu");
    expect(menu.attributes("aria-label")).toBe("Abrir menu");
    await menu.trigger("click");
    expect(menu.attributes("aria-label")).toBe("Fechar menu");
    expect(wrapper.findAll(".logout-stub")).toHaveLength(2);
    await wrapper.get(".header__mobile-nav a").trigger("click");
    expect(wrapper.find(".header__mobile-nav").exists()).toBe(false);
  });

  it("renders the same approved action without changing existing admin links", async () => {
    const wrapper = await mountHeader("/app/admin/catalog");

    expect(wrapper.text()).toContain("Moderação");
    expect(wrapper.text()).toContain("Catálogo");
    expect(wrapper.text()).toContain("Relatórios");
    expect(wrapper.get('a[href="/app/admin/catalog"]').classes()).toContain(
      "header__link--active",
    );
    expect(wrapper.findAll(".logout-stub")).toHaveLength(1);
  });

  it("keeps the dedicated administrator login outside workspace navigation", async () => {
    const wrapper = await mountHeader("/app/admin/login");

    expect(wrapper.classes()).not.toContain("header--workspace");
    expect(wrapper.text()).not.toContain("Moderação");
    expect(wrapper.text()).toContain("Entrar");
    expect(wrapper.find(".logout-stub").exists()).toBe(false);
  });
});
