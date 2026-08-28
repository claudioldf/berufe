import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import ExternalProfile from "@app/components/profile/ExternalProfile.vue";
import type { PublicProfessionalProfile } from "@app/types";

const LinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});
const ButtonStub = defineComponent({
  props: { to: { type: String, default: "" } },
  emits: ["click"],
  template:
    '<a v-if="to" :href="to" @click="$emit(\'click\')"><slot /></a><button v-else type="button" @click="$emit(\'click\')"><slot /></button>',
});

const professional: PublicProfessionalProfile = {
  id: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
  slug: "carla-pinturas",
  profileType: "external",
  claimed: false,
  name: "Carla Pinturas",
  headline: null,
  bio: null,
  avatar: null,
  primaryService: "Pintura",
  primaryServiceSlug: "pintura",
  primaryServiceIcon: "i-lucide-paintbrush",
  services: ["Pintura"],
  serviceNotes: [null],
  coverage: {
    city: {
      code: "4209102",
      name: "Joinville",
      slug: "joinville",
      stateCode: "42",
      stateAbbreviation: "SC",
      stateName: "Santa Catarina",
    },
    wholeCity: false,
    neighborhoods: [],
  },
  yearsExperience: null,
  evidence: [],
  portfolio: [],
  relationships: [],
  updatedAt: "2026-08-20T12:00:00Z",
};

describe("external public profile", () => {
  it("renders the intentionally small indication layout and a safe WhatsApp handoff", async () => {
    const contactUrl =
      "https://api.berufe.test/api/v1/public/professionals/ad59e74a-a1aa-47d5-b725-26350f0f2376/whatsapp?source=public_profile&interaction_token=signed";
    const wrapper = await mountSuspended(ExternalProfile, {
      props: {
        professional,
        contactUrl,
        supportEmailUrl: "mailto:suporte@berufe.com.br",
      },
      global: {
        stubs: {
          NuxtLink: LinkStub,
          UButton: ButtonStub,
          UIcon: true,
          DesignSystemContainer: { template: "<div><slot /></div>" },
          DesignSystemSurfaceCard: { template: "<section><slot /></section>" },
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          DesignSystemAvatar: {
            props: ["name", "fallbackIcon"],
            template:
              '<span data-avatar :data-fallback-icon="fallbackIcon">{{ name }}</span>',
          },
        },
      },
    });

    expect(wrapper.text()).toContain("Perfil adicionado por indicação");
    expect(wrapper.text()).toContain("Joinville");
    expect(wrapper.text()).not.toContain("área não informada");
    expect(wrapper.text()).toContain(
      "Este profissional ainda não reivindicou o perfil",
    );
    expect(wrapper.text()).toContain("Pintura");
    expect(wrapper.get("[data-avatar]").attributes("data-fallback-icon")).toBe(
      "i-lucide-paintbrush",
    );
    expect(wrapper.text()).not.toContain("Conexões confirmadas");
    expect(wrapper.text()).not.toContain(
      "Nenhuma conexão profissional foi confirmada publicamente ainda",
    );
    expect(wrapper.get(`a[href="${contactUrl}"]`).text()).toContain(
      "Conversar no WhatsApp",
    );
    expect(wrapper.find("img").exists()).toBe(false);
    expect(wrapper.text()).not.toContain("Frase de apresentação");
    expect(wrapper.text()).not.toContain("Conte um pouco sobre seu trabalho");
    expect(wrapper.html()).not.toMatch(/\+55|99999/);
  });
});
