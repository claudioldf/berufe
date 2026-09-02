import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import CustomerRecommendations from "@app/components/profile/CustomerRecommendations.vue";
import EvidenceStrip from "@app/components/profile/EvidenceStrip.vue";
import ProfileDetails from "@app/components/profile/ProfileDetails.vue";
import ProfileHero from "@app/components/profile/ProfileHero.vue";
import ProfileSidebar from "@app/components/profile/ProfileSidebar.vue";
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
    fallbackIcon: { type: String, default: undefined },
    verified: { type: Boolean, default: false },
  },
  template:
    '<span data-avatar :data-src="src" :data-fallback-icon="fallbackIcon" :data-verified="verified">{{ name }}</span>',
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
    primaryServiceIcon: "i-lucide-zap",
    services: ["Eletricista", "Marido de aluguel"],
    serviceNotes: ["Quadros elétricos", null],
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
      neighborhoods: [
        { code: "4209102001", name: "América" },
        { code: "4209102002", name: "Centro" },
      ],
    },
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
    evidenceSummary: {
      registeredServices: 3,
      recommendations: 1,
      hiddenRecommendations: 0,
      workedTogetherProfessionals: 2,
    },
    customerRecommendations: [],
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
        direction: "incoming",
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
    expect(wrapper.get("[data-avatar]").attributes("data-fallback-icon")).toBe(
      "i-lucide-zap",
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
      primaryService: null,
      primaryServiceSlug: null,
      primaryServiceIcon: null,
      services: [],
      serviceNotes: [],
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
    expect(wrapper.get("[data-avatar]").attributes("data-fallback-icon")).toBe(
      "i-lucide-briefcase-business",
    );
    expect(wrapper.text()).not.toContain("anos de experiência");
    expect(wrapper.find("nav").exists()).toBe(false);
  });

  it("distinguishes declarations, approved work, and relationship types without exposing phone verification", async () => {
    const profile = professional();
    const details = await mountSuspended(ProfileDetails, {
      props: {
        professional: profile,
        canRequestRelationship: false,
      },
      global: { stubs: globalStubs },
    });
    const evidence = await mountSuspended(EvidenceStrip, {
      props: {
        evidence: profile.evidence,
        summary: profile.evidenceSummary,
      },
      global: { stubs: globalStubs },
    });

    expect(details.text()).toContain("Quadros elétricos");
    expect(details.text()).not.toContain("Serviço residencial");
    expect(details.text()).toContain("Portfólio aprovado");
    expect(details.text()).toContain("1 conexão confirmada");
    expect(details.text()).toContain("Trabalharam juntos");
    expect(details.text()).toContain("Trabalharam em reformas residenciais.");
    expect(details.text()).toContain("não garante a execução");
    expect(details.text()).not.toContain("Reportar um problema à Berufe");
    expect(evidence.text()).toContain("Perfil verificado");
    expect(evidence.text()).not.toContain("Verificações da Berufe");
    expect(evidence.text()).not.toContain("Telefone confirmado");
    expect(evidence.text()).toContain("Identidade verificada");
    expect(evidence.text()).toContain("3serviços realizados");
  });

  it("discloses hidden recommendations without revealing which ones", async () => {
    const profile = professional();
    const hidden = await mountSuspended(EvidenceStrip, {
      props: {
        evidence: profile.evidence,
        summary: { ...profile.evidenceSummary, hiddenRecommendations: 2 },
      },
      global: { stubs: globalStubs },
    });
    expect(hidden.text()).toContain(
      "2 recomendações ocultadas pelo profissional.",
    );

    const none = await mountSuspended(EvidenceStrip, {
      props: {
        evidence: profile.evidence,
        summary: { ...profile.evidenceSummary, hiddenRecommendations: 0 },
      },
      global: { stubs: globalStubs },
    });
    expect(none.text()).not.toContain("ocultad");
  });

  it("renders a customer recommendation with its submission date", async () => {
    const wrapper = await mountSuspended(CustomerRecommendations, {
      props: {
        recommendations: [
          {
            id: "7849beeb-3100-4066-934f-f82d081f2580",
            displayName: "sara",
            text: "Muito bom! super recomendo esse profissional",
            submittedAt: "2026-09-02T03:00:17Z",
            verificationLabel: "Link enviado por e-mail",
          },
        ],
      },
      global: { stubs: globalStubs },
    });

    expect(wrapper.text()).toContain(
      "Muito bom! super recomendo esse profissional",
    );
    expect(wrapper.text()).toContain("sara");
    expect(wrapper.text()).toContain("02/09/2026");
    expect(wrapper.text()).not.toContain("Link enviado por e-mail");
  });

  it("hides the customer recommendations section when there are none", async () => {
    const wrapper = await mountSuspended(CustomerRecommendations, {
      props: { recommendations: [] },
      global: { stubs: globalStubs },
    });

    expect(wrapper.find("section").exists()).toBe(false);
  });

  it("hides empty portfolio and professional-relationship sections", async () => {
    const details = await mountSuspended(ProfileDetails, {
      props: {
        professional: professional({ portfolio: [], relationships: [] }),
      },
      global: { stubs: globalStubs },
    });

    expect(details.text()).not.toContain("Trabalhos que falam.");
    expect(details.text()).not.toContain("Confiança entre quem faz.");
    expect(details.text()).not.toContain(
      "ainda não possui conexões profissionais confirmadas",
    );
    expect(details.text()).toContain("Experiência que dá");
    expect(details.text()).toContain("O que a verificação significa");
  });

  it("names who authored each professional recommendation", async () => {
    const profile = professional({
      relationships: [
        {
          id: "de381ccd-d0e5-4d50-8322-a4daff09a486",
          professionalName: "Beto Lima",
          professionalSlug: "beto-lima",
          avatar: null,
          type: "recommendation",
          direction: "incoming",
          note: "Indicação recebida.",
        },
        {
          id: "8dd0465b-9efc-4f78-9981-05aa69ea7496",
          professionalName: "Carla Luz",
          professionalSlug: "carla-luz",
          avatar: null,
          type: "recommendation",
          direction: "outgoing",
          note: "Indicação enviada.",
        },
      ],
    });
    const details = await mountSuspended(ProfileDetails, {
      props: {
        professional: profile,
        canRequestRelationship: false,
      },
      global: { stubs: globalStubs },
    });

    expect(details.text()).toContain("Recomendado por Beto Lima");
    expect(details.text()).toContain("Recomendou Carla Luz");
    expect(details.text()).toContain("2 conexões confirmadas");
  });

  it("places support reporting at the bottom of the profile sidebar", async () => {
    const supportEmailUrl =
      "mailto:suporte@berufe.com.br?subject=Informacao%20sobre%20o%20perfil";
    const wrapper = await mountSuspended(ProfileSidebar, {
      props: {
        professional: professional(),
        contactUrl: "https://api.berufe.test/profile-whatsapp",
        supportEmailUrl,
      },
      global: { stubs: globalStubs },
    });

    const supportLink = wrapper.get(`a[href="${supportEmailUrl}"]`);
    expect(supportLink.text()).toContain("Reportar um problema à Berufe");
    expect(wrapper.get("aside").element.lastElementChild).toBe(
      supportLink.element,
    );
  });
});
