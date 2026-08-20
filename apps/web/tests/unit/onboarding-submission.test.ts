import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent, nextTick } from "vue";
import Wizard from "~/components/onboarding/Wizard.vue";
import type { ProfessionalWorkspace } from "~/types";

function completeWorkspace(): ProfessionalWorkspace {
  return {
    dashboard: {
      localDate: "2026-08-18",
      readiness: {
        percentage: 75,
        steps: {
          identityContact: true,
          serviceCoverage: true,
          reviewablePortfolio: true,
          approvedIdentity: false,
        },
      },
      recentQuotes: [],
    },
    pendingRelationships: [],
    relationships: [],
    profile: {
      id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
      publicSlug: "ana-souza",
      status: "draft",
      isPublic: false,
      isSearchEligible: false,
      publicationBlockers: [],
      revisionStatus: "draft",
      revisionRejectionReason: null,
      hasPublishedRevision: false,
      photo: {
        current: {
          id: "63a94f5e-1429-4ec7-bbc4-a6f805d5182d",
          status: "pending_review",
          rejectionReason: null,
          submittedAt: "2026-08-17T11:00:00Z",
        },
        hasPublishedPhoto: false,
        publishedImageUrl: null,
        latestUpload: null,
      },
      portfolioItems: [
        {
          id: "33a94f5e-1429-4ec7-bbc4-a6f805d5182d",
          title: "Cozinha iluminada",
          service: "Eletricista",
          description: "Instalação completa.",
          image: null,
          status: "pending_review",
          rejectionReason: null,
          submittedAt: "2026-08-17T12:00:00Z",
        },
      ],
      verification: {
        current: {
          id: "43a94f5e-1429-4ec7-bbc4-a6f805d5182d",
          verificationType: "identity",
          status: "pending_review",
          rejectionReason: null,
          submittedAt: "2026-08-17T12:01:00Z",
        },
      },
      identity: {
        name: "Ana Souza",
        birthdate: "1990-04-12",
        headline: "Elétrica residencial.",
        bio: "Instalações e manutenção em Joinville.",
        yearsExperience: 8,
        whatsapp: "47999991111",
        instagram: "",
        youtube: "",
      },
      services: [
        {
          id: "53a94f5e-1429-4ec7-bbc4-a6f805d5182d",
          name: "Eletricista",
          isPrimary: true,
          note: "",
        },
      ],
      coverage: { allJoinville: true, neighborhoods: [] },
    },
  };
}

const VerificationStepStub = defineComponent({
  name: "OnboardingVerificationStep",
  props: {
    submitted: Boolean,
    submitting: Boolean,
    serverError: String,
  },
  emits: ["finish"],
  template:
    '<button data-submit type="button" @click="$emit(\'finish\')">Concluir onboarding</button>',
});

const SuccessStub = defineComponent({
  name: "OnboardingSuccess",
  template: "<div data-success>Perfil enviado</div>",
});

describe("professional onboarding submission", () => {
  it("shows success only after Rails accepts the final persisted checklist", async () => {
    const workspace = completeWorkspace();
    const submitProfile = vi.fn().mockResolvedValue(undefined);
    const wrapper = mount(Wizard, {
      props: {
        services: [
          {
            id: workspace.profile.services[0]!.id,
            name: "Eletricista",
            slug: "eletricista",
            category: "Instalações",
            icon: "i-lucide-zap",
            description: "Instalações elétricas.",
            aliases: [],
          },
        ],
        neighborhoods: [],
        workspace,
        saveIdentity: vi.fn(),
        saveSupply: vi.fn(),
        saveVerification: vi.fn(),
        uploadPhoto: vi.fn(),
        retryPhoto: vi.fn(),
        submitProfile,
      },
      global: {
        stubs: {
          DesignSystemContainer: { template: "<div><slot /></div>" },
          DesignSystemSurfaceCard: { template: "<section><slot /></section>" },
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          OnboardingProgress: true,
          OnboardingProfileStep: true,
          OnboardingServicesStep: true,
          OnboardingVerificationStep: VerificationStepStub,
          OnboardingSuccess: SuccessStub,
          UButton: { template: "<button><slot /></button>" },
          UIcon: true,
        },
      },
    });
    await flushPromises();

    expect(wrapper.find("[data-success]").exists()).toBe(false);
    await wrapper.get("[data-submit]").trigger("click");
    await flushPromises();
    expect(submitProfile).toHaveBeenCalledOnce();
    expect(wrapper.find("[data-success]").exists()).toBe(false);

    await wrapper.setProps({
      workspace: {
        ...workspace,
        profile: {
          ...workspace.profile,
          status: "published",
          isPublic: true,
          revisionStatus: "pending_review",
        },
      },
    });
    await nextTick();
    expect(wrapper.find("[data-success]").exists()).toBe(true);
  });
});
