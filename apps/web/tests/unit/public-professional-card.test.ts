import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import ProfessionalCard from "@app/components/public/ProfessionalCard.vue";
import type { PublicProfessionalCard } from "@app/types";
import {
  buildPublicProfileWhatsAppUrl,
  buildPublicProfileResultUrl,
  buildSearchResultWhatsAppUrl,
} from "@app/utils/publicProfiles";

const LinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});
const ButtonStub = defineComponent({
  props: {
    to: { type: String, required: true },
    label: { type: String, required: true },
  },
  emits: ["click"],
  template: '<a :href="to" @click="$emit(\'click\')">{{ label }}</a>',
});
const AvatarStub = defineComponent({
  props: {
    name: { type: String, required: true },
    src: { type: String, default: undefined },
  },
  template:
    '<img v-if="src" :src="src" :alt="`Foto de ${name}`"><span v-else data-avatar-fallback>{{ name.slice(0, 1) }}</span>',
});
const EvidenceStub = defineComponent({
  props: { evidence: { type: Object, required: true } },
  template: "<span>{{ evidence.label }}</span>",
});

function professional(
  overrides: Partial<PublicProfessionalCard> = {},
): PublicProfessionalCard {
  return {
    id: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
    slug: "ana-souza",
    profileType: "self_service",
    claimed: true,
    name: "Ana Souza",
    headline: "Elétrica residencial.",
    photoUrl: null,
    primaryService: {
      id: "c43071a5-4c47-4324-99ef-41846ee35538",
      name: "Eletricista",
      slug: "eletricista",
    },
    matchingService: {
      id: "c43071a5-4c47-4324-99ef-41846ee35538",
      name: "Eletricista",
      slug: "eletricista",
    },
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
      neighborhoods: [{ code: "4209102007", name: "América" }],
    },
    verificationLabels: [
      {
        type: "phone",
        label: "Telefone confirmado",
        verifiedAt: null,
      },
      {
        type: "identity",
        label: "Identidade verificada",
        verifiedAt: "2026-08-15T12:00:00Z",
      },
    ],
    portfolioCount: 3,
    relationshipCount: 2,
    publicSnapshotUpdatedAt: "2026-08-01T12:00:00Z",
    ...overrides,
  };
}

describe("public professional result card", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-08-17T12:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("renders only API evidence and the preserved result links", async () => {
    const profileUrl = buildPublicProfileResultUrl({
      slug: "ana-souza",
      encodedExpression: "ZWxldHJpY2lzdGE",
      interactionToken: "signed context",
      requestMessage: "Eu preciso trocar a fiação da cozinha.",
    });
    const contactUrl = buildSearchResultWhatsAppUrl({
      apiBaseUrl: "https://api.berufe.test",
      professionalId: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
      interactionToken: "signed context",
      requestMessage: "Eu preciso trocar a fiação da cozinha.",
    });
    const parsedContactUrl = new URL(contactUrl);
    expect(parsedContactUrl.searchParams.get("interaction_token")).toBe(
      "signed context",
    );
    expect(parsedContactUrl.searchParams.has("interactionToken")).toBe(false);
    expect(parsedContactUrl.searchParams.get("request_message")).toBe(
      "Eu preciso trocar a fiação da cozinha.",
    );
    const parsedProfileUrl = new URL(profileUrl, "https://berufe.test");
    expect(parsedProfileUrl.searchParams.get("pedido")).toBe(
      "Eu preciso trocar a fiação da cozinha.",
    );
    const wrapper = await mountSuspended(ProfessionalCard, {
      props: { professional: professional(), profileUrl, contactUrl },
      global: {
        stubs: {
          NuxtLink: LinkStub,
          UButton: ButtonStub,
          UIcon: true,
          DesignSystemAvatar: AvatarStub,
          PublicEvidenceBadge: EvidenceStub,
        },
      },
    });

    expect(wrapper.text()).toContain("Eletricista");
    expect(wrapper.text()).toContain("Atende América");
    expect(wrapper.text()).toContain("Telefone confirmado");
    expect(wrapper.text()).toContain("Identidade verificada");
    expect(wrapper.text()).toContain("3 trabalhos");
    expect(wrapper.text()).toContain("2 conexões profissionais");
    expect(wrapper.text()).toContain("Atualizado recentemente");
    expect(wrapper.find("[data-avatar-fallback]").exists()).toBe(true);
    expect(wrapper.find('[name="i-lucide-briefcase-business"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[name="i-lucide-sparkles"]').exists()).toBe(false);
    expect(wrapper.findAll(`a[href="${profileUrl}"]`)).toHaveLength(3);
    const contact = wrapper.get(`a[href="${contactUrl}"]`);
    expect(contact.text()).toBe("WhatsApp");
    await contact.trigger("click");
    expect(wrapper.emitted("contact")?.[0]).toEqual([
      wrapper.props("professional"),
    ]);
    await wrapper.setProps({
      professional: professional({ relationshipCount: 1 }),
    });
    expect(wrapper.text()).toContain("1 conexão profissional");
    expect(wrapper.text()).not.toMatch(/pontua|preço|disponível|patrocinad/i);
  });

  it("hides stale and unapproved identity presentation", async () => {
    const wrapper = await mountSuspended(ProfessionalCard, {
      props: {
        professional: professional({
          verificationLabels: [
            {
              type: "phone",
              label: "Telefone confirmado",
              verifiedAt: null,
            },
          ],
          publicSnapshotUpdatedAt: "2026-04-01T12:00:00Z",
        }),
        profileUrl: "/profissionais/ana-souza",
        contactUrl: "https://api.berufe.test/whatsapp",
      },
      global: {
        stubs: {
          NuxtLink: LinkStub,
          UButton: ButtonStub,
          UIcon: true,
          DesignSystemAvatar: AvatarStub,
          PublicEvidenceBadge: EvidenceStub,
        },
      },
    });

    expect(wrapper.text()).not.toContain("Atualizado recentemente");
    expect(wrapper.text()).not.toContain("Verificada");
    expect(wrapper.text()).toContain("Telefone confirmado");
  });

  it("builds the profile handoff without exposing a phone number", () => {
    const url = buildPublicProfileWhatsAppUrl({
      apiBaseUrl: "https://api.berufe.test/",
      professionalId: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
      interactionToken: "signed profile context",
      requestMessage: "Eu preciso trocar a fiação da cozinha.",
    });

    expect(url).toBe(
      "https://api.berufe.test/api/v1/public/professionals/ad59e74a-a1aa-47d5-b725-26350f0f2376/whatsapp?source=public_profile&interaction_token=signed+profile+context&request_message=Eu+preciso+trocar+a+fia%C3%A7%C3%A3o+da+cozinha.",
    );
    expect(url).not.toContain("interactionToken");
    expect(url).not.toContain("wa.me");
  });

  it("identifies external results and uses the missing-area fallback", async () => {
    const wrapper = await mountSuspended(ProfessionalCard, {
      props: {
        professional: professional({
          profileType: "external",
          claimed: false,
          headline: null,
          photoUrl: null,
          coverage: {
            city: professional().coverage.city,
            wholeCity: false,
            neighborhoods: [],
          },
          verificationLabels: [],
          portfolioCount: 0,
        }),
        profileUrl: "/profissionais/ana-souza",
        contactUrl: "https://api.berufe.test/whatsapp",
      },
      global: {
        stubs: {
          NuxtLink: LinkStub,
          UButton: ButtonStub,
          UIcon: true,
          DesignSystemAvatar: AvatarStub,
          PublicEvidenceBadge: EvidenceStub,
        },
      },
    });

    expect(wrapper.text()).toContain("Perfil por indicação");
    expect(wrapper.text()).toContain("Joinville · área não informada");
    expect(wrapper.text()).not.toContain("Elétrica residencial");
  });
});
