import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import SearchFailureCard from "@app/components/public/SearchFailureCard.vue";

const services = [
  {
    id: "c43071a5-4c47-4324-99ef-41846ee35538",
    name: "Eletricista",
    slug: "eletricista",
    category: "instalacoes",
    icon: "i-lucide-zap",
    description: "Instalações elétricas residenciais.",
    aliases: ["elétrica"],
  },
];
const cities = [
  { id: "joinville-sc", name: "Joinville" as const, stateCode: "SC" as const },
];

const ButtonStub = defineComponent({
  name: "UButton",
  props: {
    type: { type: String, default: "button" },
  },
  emits: ["click"],
  template: '<button :type="type" @click="$emit(\'click\')"><slot /></button>',
});

const stubs = {
  DesignSystemSurfaceCard: {
    template: '<article class="surface-card"><slot /></article>',
  },
  UButton: ButtonStub,
  UIcon: true,
  PublicStructuredSearchFallback: {
    props: ["services", "cities", "loading"],
    emits: ["submit"],
    template: `
      <button
        class="structured-search-stub"
        @click="$emit('submit', {
          serviceId: services[0].id,
          serviceName: services[0].name,
          stateCode: cities[0].stateCode,
          city: cities[0].name
        })"
      >
        Buscar com serviço e cidade
      </button>
    `,
  },
};

describe("search failure card", () => {
  it("presents a friendly retryable search error", async () => {
    const wrapper = await mountSuspended(SearchFailureCard, {
      props: {
        message:
          "Não conseguimos interpretar sua busca agora. Tente novamente.",
        services,
        cities,
      },
      global: { stubs },
    });

    expect(wrapper.get('[role="alert"]').text()).toContain(
      "Não foi possível concluir a busca.",
    );
    expect(wrapper.text()).toContain(
      "Não conseguimos interpretar sua busca agora. Tente novamente.",
    );
    expect(wrapper.text()).toContain("Escolha o serviço e a cidade");
    expect(wrapper.text()).toContain(
      "Continue a busca usando os filtros disponíveis.",
    );
    expect(wrapper.find('[name="i-lucide-user-search"]').exists()).toBe(true);
    expect(wrapper.find('[name="i-lucide-sparkles"]').exists()).toBe(false);

    await wrapper.get(".search-failure__retry").trigger("click");
    expect(wrapper.emitted("retry")).toHaveLength(1);

    await wrapper.get(".structured-search-stub").trigger("click");
    expect(wrapper.emitted("search")?.[0]?.[0]).toEqual({
      serviceId: services[0]?.id,
      serviceName: "Eletricista",
      stateCode: "SC",
      city: "Joinville",
    });
  });

  it("keeps the structured form when the current failure cannot be retried", async () => {
    const wrapper = await mountSuspended(SearchFailureCard, {
      props: {
        message: "Revise os campos informados.",
        services,
        cities,
        canRetry: false,
      },
      global: { stubs },
    });

    expect(wrapper.find(".search-failure__retry").exists()).toBe(false);
    expect(wrapper.text()).toContain("Revise os campos informados.");
    expect(wrapper.text()).toContain("Escolha o serviço e a cidade");
    expect(wrapper.find(".structured-search-stub").exists()).toBe(true);
    expect(wrapper.find('[name="i-lucide-user-search"]').exists()).toBe(true);

    await wrapper.get(".structured-search-stub").trigger("click");
    expect(wrapper.emitted("search")?.[0]?.[0]).toEqual({
      serviceId: services[0]?.id,
      serviceName: "Eletricista",
      stateCode: "SC",
      city: "Joinville",
    });
  });
});
