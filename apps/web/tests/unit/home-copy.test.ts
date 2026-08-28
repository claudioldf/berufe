import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import Hero from "~/components/home/Hero.vue";
import ProfessionalCta from "~/components/home/ProfessionalCta.vue";
import Trust from "~/components/home/Trust.vue";
import { fallbackSearchLocation } from "~/utils/searchLocation";

const AvatarStub = defineComponent({
  props: { name: { type: String, required: true } },
  template: "<span>{{ name }}</span>",
});

const sharedStubs = {
  DesignSystemContainer: { template: "<div><slot /></div>" },
  DesignSystemEyebrow: { template: "<p><slot /></p>" },
  DesignSystemHeading: { template: "<h2><slot /></h2>" },
  DesignSystemPageSection: { template: "<section><slot /></section>" },
  DesignSystemSectionCopy: { template: "<p><slot /></p>" },
  UIcon: true,
};

describe("home marketing copy", () => {
  it("describes the customer value without synthetic proof or internal jargon", () => {
    const wrapper = mount(Hero, {
      props: {
        location: fallbackSearchLocation,
        cities: [fallbackSearchLocation],
        locationSource: "fallback",
      },
      global: {
        stubs: {
          ...sharedStubs,
          DesignSystemAvatar: AvatarStub,
          PublicExpressionSearch: true,
        },
      },
    });

    expect(wrapper.get(".hero__copy").text()).toContain(
      "Encontre profissionais para cuidar da sua casa e do seu dia a dia.",
    );
    expect(wrapper.get(".hero__profile-chip").text()).toContain(
      "Profissionais em Joinville",
    );
    expect(wrapper.get(".hero__trust-chip").text()).toMatch(
      /Contato\s*direto pelo\s*WhatsApp/,
    );
    expect(wrapper.text()).not.toContain("evidências");
    expect(wrapper.get(".hero__profile-chip").text()).not.toContain(
      "Marcos Alves",
    );
    expect(wrapper.text()).not.toContain("+50.000");
  });

  it("explains trust with concrete profile information", () => {
    const wrapper = mount(Trust, {
      global: { stubs: sharedStubs },
    });

    expect(wrapper.text()).toContain("Como a Berufe ajuda");
    expect(wrapper.text()).toContain("Conte o que você precisa");
    expect(wrapper.text()).toContain("Compare os profissionais");
    expect(wrapper.text()).toContain("Fale direto pelo WhatsApp");
    expect(wrapper.text()).toContain("trabalhos publicados");
    expect(wrapper.text()).toContain("referências de cada perfil");
    expect(wrapper.text()).not.toContain("evidências");
  });

  it("presents the free professional profile as a reputation tool", () => {
    const wrapper = mount(ProfessionalCta, {
      global: {
        stubs: {
          ...sharedStubs,
          UButton: { template: "<a><slot /></a>" },
        },
      },
    });

    expect(wrapper.text()).toContain("Você presta serviços?");
    expect(wrapper.text()).toContain("Fortaleça sua reputação.");
    expect(wrapper.text()).toContain("peça referências");
    expect(wrapper.text()).toContain("sem pagar por contatos");
    expect(wrapper.text()).toContain("Criar perfil grátis");
    expect(wrapper.text()).not.toContain("evidências");
  });
});
