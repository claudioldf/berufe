import { mount } from "@vue/test-utils";
import DiscoveryHealth from "@app/components/admin/reports/DiscoveryHealth.vue";
import SupplyHealth from "@app/components/admin/reports/SupplyHealth.vue";
import TrustOperations from "@app/components/admin/reports/TrustOperations.vue";
import type { ReportPeriodData } from "@app/types";

describe("administrator report widgets", () => {
  it("renders the approved five-stage discovery funnel and inactive catalog action", () => {
    const discovery: ReportPeriodData["discovery"] = {
      stages: [
        {
          key: "searches",
          label: "Buscas",
          numerator: 3,
          denominator: 3,
          rate: 1,
        },
        {
          key: "results",
          label: "Com resultado",
          numerator: 2,
          denominator: 3,
          rate: 2 / 3,
        },
        {
          key: "choice",
          label: "Com 3+ opções",
          numerator: 1,
          denominator: 3,
          rate: 1 / 3,
        },
        {
          key: "profile_open",
          label: "Perfil aberto",
          numerator: 1,
          denominator: 3,
          rate: 1 / 3,
        },
        {
          key: "contact",
          label: "Contato iniciado",
          numerator: 0,
          denominator: 3,
          rate: 0,
        },
      ],
      profileViews: 1,
      whatsappHandoffs: 0,
      demand: [],
      gaps: [
        {
          service: "Drywall",
          location: "Joinville",
          searches: 3,
          professionals: 0,
          catalogStatus: "inactive",
        },
      ],
    };
    const wrapper = mount(DiscoveryHealth, { props: { discovery } });

    expect(wrapper.findAll(".discovery-stage")).toHaveLength(5);
    expect(wrapper.text()).toContain("Contato iniciado");
    expect(wrapper.text()).toContain("Avaliar catálogo");
  });

  it("renders server-owned null funnel rates as a dash", () => {
    const supply: ReportPeriodData["supply"] = {
      targetMinimum: 30,
      targetMaximum: 50,
      funnel: [
        { key: "registered", label: "Cadastrados", value: 0, rate: null },
        {
          key: "verified",
          label: "Identidade verificada",
          value: 0,
          rate: null,
        },
      ],
      activation: [
        {
          key: "all",
          label: "Perfil ativado",
          value: 0,
          total: 0,
          rate: null,
          description: "cumpre os 3 critérios",
          icon: "i-lucide-sparkles",
        },
      ],
    };
    const wrapper = mount(SupplyHealth, { props: { supply } });

    expect(wrapper.get(".funnel__row:nth-child(2) em").text()).toBe("—");
    expect(wrapper.text()).toContain("0/0");
  });

  it("labels relationship responses and repeat quote creators without deriving rates", () => {
    const trust: ReportPeriodData["trust"] = {
      funnels: [
        {
          key: "relationships",
          label: "Relações profissionais",
          started: 2,
          responded: 1,
          approved: 0,
          responseRate: { numerator: 1, denominator: 2, rate: 0.5 },
          approvalRate: { numerator: 0, denominator: 1, rate: 0 },
        },
      ],
    };
    const quotes: ReportPeriodData["quotes"] = {
      created: 0,
      shared: 0,
      shareRate: { numerator: 0, denominator: 0, rate: null },
      uniqueCreators: 0,
      repeatCreators: 0,
    };
    const operations: ReportPeriodData["operations"] = {
      pending: 0,
      oldestPendingHours: 0,
      medianReviewHours: 0,
      p90ReviewHours: 0,
      rejected: 0,
      reviewed: 0,
      approvalRate: { numerator: 0, denominator: 0, rate: null },
      hidden: 0,
    };
    const wrapper = mount(TrustOperations, {
      props: { trust, quotes, operations },
    });

    expect(wrapper.text()).toContain("respondidas");
    expect(wrapper.text()).toContain("2+ no período");
    expect(wrapper.text()).toContain("— compartilhados");
  });
});
