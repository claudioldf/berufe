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
      allJoinville: false,
      neighborhoods: [{ code: "america", name: "América" }],
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
      serviceSlug: "eletricista",
      neighborhoodCode: "america",
      interactionToken: "signed context",
    });
    const contactUrl = buildSearchResultWhatsAppUrl({
      apiBaseUrl: "https://api.berufe.test",
      professionalId: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
      interactionToken: "signed context",
    });
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
    expect(wrapper.text()).toContain("2 relações profissionais");
    expect(wrapper.text()).toContain("Atualizado recentemente");
    expect(wrapper.find("[data-avatar-fallback]").exists()).toBe(true);
    expect(wrapper.findAll(`a[href="${profileUrl}"]`)).toHaveLength(3);
    const contact = wrapper.get(`a[href="${contactUrl}"]`);
    expect(contact.text()).toBe("WhatsApp");
    await contact.trigger("click");
    expect(wrapper.emitted("contact")?.[0]).toEqual([
      wrapper.props("professional"),
    ]);
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
    });

    expect(url).toBe(
      "https://api.berufe.test/api/v1/public/professionals/ad59e74a-a1aa-47d5-b725-26350f0f2376/whatsapp?source=public_profile&interactionToken=signed+profile+context",
    );
    expect(url).not.toContain("wa.me");
  });
});
