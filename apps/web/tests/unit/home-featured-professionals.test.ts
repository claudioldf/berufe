import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import FeaturedProfessionals from "~/components/home/FeaturedProfessionals.vue";
import type { PublicProfessionalCard } from "~/types";

const NuxtLinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});
const AvatarStub = defineComponent({
  props: {
    name: { type: String, required: true },
    src: { type: String, default: undefined },
  },
  template:
    '<img v-if="src" :src="src" :alt="`Foto de ${name}`"><span v-else>{{ name.slice(0, 1) }}</span>',
});

function professional(
  overrides: Partial<PublicProfessionalCard> = {},
): PublicProfessionalCard {
  return {
    id: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
    slug: "ana-souza",
    name: "Ana Souza",
    headline: "Elétrica residencial.",
    photoUrl: "https://api.berufe.test/photo.jpg",
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
      neighborhoods: [
        { code: "america", name: "América" },
        { code: "saguacu", name: "Saguaçu" },
      ],
    },
    verificationLabels: [
      {
        type: "identity",
        label: "Identidade verificada",
        verifiedAt: "2026-08-16T12:00:00Z",
      },
    ],
    portfolioCount: 3,
    relationshipCount: 2,
    publicSnapshotUpdatedAt: "2026-08-17T12:00:00Z",
    ...overrides,
  };
}

describe("home featured professionals", () => {
  it("renders only Rails-backed card evidence and stable profile links", async () => {
    const wrapper = await mountSuspended(FeaturedProfessionals, {
      props: {
        professionals: [
          professional(),
          professional({
            id: "eea71880-120c-44d0-97c8-76a46ef3444b",
            slug: "beto-lima",
            name: "Beto Lima",
            photoUrl: null,
            primaryService: null,
            coverage: {
              city: professional().coverage.city,
              wholeCity: true,
              neighborhoods: [],
            },
            verificationLabels: [],
            relationshipCount: 0,
          }),
        ],
      },
      global: {
        stubs: {
          DesignSystemPageSection: { template: "<section><slot /></section>" },
          DesignSystemContainer: { template: "<div><slot /></div>" },
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          DesignSystemHeading: { template: "<h2><slot /></h2>" },
          DesignSystemAvatar: AvatarStub,
          NuxtLink: NuxtLinkStub,
          UButton: { template: "<a><slot /></a>" },
          UIcon: true,
        },
      },
    });

    expect(wrapper.get('a[href="/profissionais/ana-souza"]').text()).toContain(
      "Ana Souza",
    );
    expect(wrapper.text()).toContain("Eletricista");
    expect(wrapper.text()).toContain("América e Saguaçu");
    expect(wrapper.text()).toContain("Toda Joinville");
    expect(wrapper.text()).toContain("2 conexões profissionais");
    expect(wrapper.text()).toContain("0 conexões profissionais");
    expect(wrapper.text().match(/Identidade verificada/g)).toHaveLength(1);
    const serviceBadges = wrapper.findAll(".featured-card__service");
    expect(serviceBadges).toHaveLength(1);
    expect(serviceBadges[0]?.text()).toBe("Eletricista");
    expect(
      wrapper.find('img[src="https://api.berufe.test/photo.jpg"]').exists(),
    ).toBe(true);
    expect(wrapper.html()).not.toContain("whatsapp");
  });
});
