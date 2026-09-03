import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import AppHeader from "~/components/AppHeader.vue";

// Isolated from app-header.test.ts on purpose: that file exercises the real
// useApplicationSession()/restoreSession() flow through the global middleware,
// and mounting two authenticated professional-workspace sessions back to back
// there races the composable's shared in-flight restoration promise. Mocking
// the composable directly here keeps this assertion deterministic.
const mocks = vi.hoisted(() => ({
  session: {
    value: null as { impersonating: boolean } | null,
  },
}));

vi.mock("~/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({
    account: {
      value: { role: "professional", registrationCompleted: true },
    },
    session: mocks.session,
    status: { value: "authenticated" },
    restoreSession: vi.fn().mockResolvedValue(true),
  }),
}));

const NuxtLinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});

async function mountHeader(impersonating: boolean) {
  mocks.session.value = { impersonating };

  return mountSuspended(AppHeader, {
    route: "/app/professional/profile",
    global: {
      stubs: {
        DesignSystemContainer: { template: "<div><slot /></div>" },
        DesignSystemBrand: { template: "<span>Berufe</span>" },
        NuxtLink: NuxtLinkStub,
        UButton: true,
        UIcon: true,
        AuthSessionLogoutButton: {
          template: '<button class="logout-stub">Sair</button>',
        },
        DashboardNotificationsHub: true,
      },
    },
  });
}

describe("application header during delegated administrator access", () => {
  it("hides sign-out while an administrator is delegated into a professional workspace", async () => {
    const wrapper = await mountHeader(true);

    expect(wrapper.classes()).toContain("header--workspace");
    expect(wrapper.find(".logout-stub").exists()).toBe(false);

    const menu = wrapper.get(".header__menu");
    await menu.trigger("click");
    expect(wrapper.find(".logout-stub").exists()).toBe(false);
  });

  it("keeps sign-out available for an ordinary professional session", async () => {
    const wrapper = await mountHeader(false);

    expect(wrapper.classes()).toContain("header--workspace");
    expect(wrapper.find(".logout-stub").exists()).toBe(true);
  });
});
