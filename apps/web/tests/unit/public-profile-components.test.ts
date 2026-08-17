import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import EvidenceStrip from "@app/components/profile/EvidenceStrip.vue";
import ProfileDetails from "@app/components/profile/ProfileDetails.vue";
import ProfileHero from "@app/components/profile/ProfileHero.vue";
import type { PublicProfessionalProfile } from "@app/types";

const LinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});
const ButtonStub = defineComponent({
  props: { to: { type: String, default: undefined } },
  emits: ["click"],
  template:
    '<a v-if="to" :href="to" @click="$emit(\'click\')"><slot /></a><button v-else @click="$emit(\'click\')"><slot /></button>',
});
const AvatarStub = defineComponent({
  props: {
    name: { type: String, required: true },
    src: { type: String, default: undefined },
    verified: { type: Boolean, default: false },
  },
  template:
    '<span data-avatar :data-src="src" :data-verified="verified">{{ name }}</span>',
});
const EvidenceStub = defineComponent({
  props: { evidence: { type: Object, required: true } },
  template: "<span>{{ evidence.label }}</span>",
});

function professional(
  overrides: Partial<PublicProfessionalProfile> = {},
): PublicProfessionalProfile {
  return {
    id: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
    slug: "ana-souza",
    name: "Ana Souza",
    headline: "Elétrica residencial.",
    bio: "Instalações e reparos residenciais.",
    avatar: null,
    primaryService: "Eletricista",
    primaryServiceSlug: "eletricista",
    services: ["Eletricista", "Marido de aluguel"],
    serviceNotes: ["Quadros elétricos", null],
    neighborhoods: ["América", "Centro"],
    allJoinville: false,
    yearsExperience: 11,
    evidence: [
      {
        id: "phone",
        type: "phone",
        label: "Telefone confirmado",
        verifiedAt: null,
      },
      {
        id: "identity",
        type: "identity",
        label: "Identidade verificada",
        verifiedAt: "2026-08-16T12:00:00Z",
      },
    ],
    portfolio: [
      {
        id: "b9029f26-f2c1-4001-9696-cf34d7259999",
        title: "Quadro organizado",
        service: "Eletricista",
        description: "Organização e identificação.",
        image: "https://api.berufe.test/portfolio.png",
      },
    ],
    relationships: [
      {
        id: "de381ccd-d0e5-4d50-8322-a4daff09a486",
        professionalName: "Beto Lima",
        professionalSlug: "beto-lima",
        avatar: null,
        type: "worked_together",
        note: "Trabalharam em reformas residenciais.",
      },
    ],
    updatedAt: "2026-08-17T12:00:00Z",
    instagram: "https://www.instagram.com/berufe.ana/",
    youtube: "https://www.youtube.com/@berufe-ana",
    ...overrides,
  };
}

const globalStubs = {
  DesignSystemContainer: { template: "<div><slot /></div>" },
  DesignSystemEyebrow: { template: "<span><slot /></span>" },
  DesignSystemSurfaceCard: { template: "<div><slot /></div>" },
  DesignSystemAvatar: AvatarStub,
  PublicEvidenceBadge: EvidenceStub,
  NuxtLink: LinkStub,
  UButton: ButtonStub,
  UIcon: true,
};

describe("public profile components", () => {
  it("renders approved identity, declarations, social links, and preserved actions", async () => {
    const profile = professional();
    const wrapper = await mountSuspended(ProfileHero, {
      props: {
        professional: profile,
        resultsUrl: "/encontrar?servico=eletricista&bairro=america",
        contactUrl: "https://api.berufe.test/profile-whatsapp",
        socialLinks: [
          {
            platform: "instagram",
            label: "Instagram",
            icon: "i-lucide-instagram",
            url: profile.instagram!,
          },
          {
            platform: "youtube",
            label: "YouTube",
            icon: "i-lucide-youtube",
            url: profile.youtube!,
          },
        ],
      },
      global: { stubs: globalStubs },
    });

    expect(wrapper.text()).toContain("Ana Souza");
    expect(wrapper.text()).toContain("Eletricista");
    expect(wrapper.text()).toContain("América, Centro");
    expect(wrapper.text()).toContain("11 anos de experiência declarada");
    expect(wrapper.get("[data-avatar]").attributes("data-verified")).toBe(
      "true",
    );
    expect(
      wrapper.get('a[href="/encontrar?servico=eletricista&bairro=america"]'),
    ).toBeTruthy();
    expect(
      wrapper.get('a[href="https://api.berufe.test/profile-whatsapp"]'),
    ).toBeTruthy();
    for (const link of wrapper.findAll("nav a")) {
      expect(link.attributes()).toMatchObject({
        target: "_blank",
        rel: "noopener noreferrer",
      });
    }
  });

  it("keeps unapproved identity and absent optional profile claims out of the hero", async () => {
    const profile = professional({
      avatar: null,
      yearsExperience: null,
      evidence: [
        {
          id: "phone",
          type: "phone",
          label: "Telefone confirmado",
          verifiedAt: null,
        },
      ],
      instagram: undefined,
      youtube: undefined,
    });
    const wrapper = await mountSuspended(ProfileHero, {
      props: {
        professional: profile,
        resultsUrl: "/encontrar?servico=eletricista&bairro=all",
        contactUrl: "https://api.berufe.test/profile-whatsapp",
        socialLinks: [],
      },
      global: { stubs: globalStubs },
    });

    expect(wrapper.get("[data-avatar]").attributes("data-verified")).toBe(
      "false",
    );
    expect(wrapper.text()).not.toContain("anos de experiência");
    expect(wrapper.find("nav").exists()).toBe(false);
  });

  it("distinguishes declarations, approved work, and relationship types without adding evidence", async () => {
    const profile = professional();
    const details = await mountSuspended(ProfileDetails, {
      props: {
        professional: profile,
        canRequestRelationship: false,
        supportEmailUrl: "mailto:suporte@berufe.com.br",
      },
      global: { stubs: globalStubs },
    });
    const evidence = await mountSuspended(EvidenceStrip, {
      props: { evidence: profile.evidence },
      global: { stubs: globalStubs },
    });

    expect(details.text()).toContain("Quadros elétricos");
    expect(details.text()).not.toContain("Serviço residencial");
    expect(details.text()).toContain("Portfólio aprovado");
    expect(details.text()).toContain("Trabalharam juntos");
    expect(details.text()).toContain("Trabalharam em reformas residenciais.");
    expect(details.text()).toContain("não representam uma verificação");
    expect(details.text()).toContain("não garante a execução");
    expect(evidence.text()).toContain("Telefone confirmado");
    expect(evidence.text()).toContain("Identidade verificada");
  });
});
