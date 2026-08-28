import { mountSuspended } from "@nuxt/test-utils/runtime";
import SearchRateLimitCard from "@app/components/public/SearchRateLimitCard.vue";

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
  {
    id: "4209102",
    name: "Joinville" as const,
    stateCode: "SC" as const,
    stateSlug: "sc",
    citySlug: "joinville",
  },
];

const stubs = {
  DesignSystemSurfaceCard: {
    template: '<article class="surface-card"><slot /></article>',
  },
  UIcon: true,
  PublicStructuredSearchFallback: {
    props: ["services", "cities", "loading"],
    emits: ["submit"],
    template:
      "<button @click=\"$emit('submit', { serviceId: services[0].id, serviceName: services[0].name, cityCode: cities[0].id, stateCode: cities[0].stateCode, city: cities[0].name, stateSlug: cities[0].stateSlug, citySlug: cities[0].citySlug })\">Buscar novamente</button>",
  },
};

describe("search rate limit card", () => {
  it("presents throttling as a friendly temporary pause", async () => {
    const wrapper = await mountSuspended(SearchRateLimitCard, {
      props: { services, cities },
      global: { stubs },
    });

    const status = wrapper.get('[role="status"]');
    expect(status.attributes("aria-live")).toBe("polite");
    expect(status.text()).toContain("Uma pausa rapidinha");
    expect(status.text()).toContain(
      "A busca por descrição volta em alguns minutos",
    );
    expect(status.text()).toContain("Você fez várias buscas seguidas");
    expect(status.text()).toContain(
      "Para continuar agora, escolha o serviço e a cidade abaixo.",
    );
    expect(status.text()).not.toContain("Ou podemos tentar de outra forma.");
    expect(wrapper.get("button").text()).toContain("Buscar novamente");
    expect(wrapper.text()).not.toContain("Não foi possível concluir");
    expect(wrapper.text().toLocaleLowerCase("pt-BR")).not.toContain("erro");

    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("search")?.[0]?.[0]).toEqual({
      serviceId: services[0]?.id,
      serviceName: "Eletricista",
      cityCode: "4209102",
      stateCode: "SC",
      city: "Joinville",
      stateSlug: "sc",
      citySlug: "joinville",
    });
  });
});
