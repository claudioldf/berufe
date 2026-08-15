import { computed, onMounted, readonly } from "vue";
import type {
  OnboardingChecklistItem,
  OnboardingCompletionState,
  OnboardingFileValidation,
  OnboardingPortfolioSubmission,
  OnboardingProfileErrors,
  OnboardingServicesErrors,
  OnboardingStepDefinition,
  OnboardingStepId,
  ProfessionalOnboardingState,
  ProfessionalProfileDraft,
} from "~/types";

export const professionalOnboardingStorageKey =
  "berufe:professional-onboarding:v1";
export const onboardingImageMaxBytes = 10 * 1024 * 1024;

export const professionalOnboardingSteps: OnboardingStepDefinition[] = [
  {
    id: "profile",
    label: "Perfil e contato",
    description: "Nome, apresentação e WhatsApp",
    icon: "i-lucide-user-round",
  },
  {
    id: "services",
    label: "Serviços e cobertura",
    description: "O que você faz e onde atende",
    icon: "i-lucide-briefcase-business",
  },
  {
    id: "portfolio",
    label: "Primeiro trabalho",
    description: "Uma foto que mostre seu serviço",
    icon: "i-lucide-image-plus",
  },
  {
    id: "verification",
    label: "Verificação",
    description: "Envio seguro da sua identidade",
    icon: "i-lucide-shield-check",
  },
];

export function createEmptyProfessionalProfileDraft(): ProfessionalProfileDraft {
  return {
    name: "",
    headline: "",
    bio: "",
    yearsExperience: 0,
    whatsapp: "",
    instagram: "",
    youtube: "",
    selectedServices: [],
    primaryService: "",
    allJoinville: false,
    selectedNeighborhoods: [],
  };
}

function createEmptyCompletionState(): OnboardingCompletionState {
  return {
    profile: null,
    services: null,
    portfolio: null,
    verification: null,
  };
}

export function createInitialProfessionalOnboardingState(): ProfessionalOnboardingState {
  return {
    version: 1,
    initialized: false,
    profile: createEmptyProfessionalProfileDraft(),
    portfolio: null,
    verificationStatus: "not_started",
    completion: createEmptyCompletionState(),
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isNullableString(value: unknown): value is string | null {
  return value === null || typeof value === "string";
}

function parseProfileDraft(value: unknown): ProfessionalProfileDraft | null {
  if (!isRecord(value)) return null;
  const stringKeys = [
    "name",
    "headline",
    "bio",
    "whatsapp",
    "instagram",
    "youtube",
    "primaryService",
  ] as const;
  if (stringKeys.some((key) => typeof value[key] !== "string")) return null;
  if (typeof value.yearsExperience !== "number") return null;
  if (typeof value.allJoinville !== "boolean") return null;
  if (!Array.isArray(value.selectedServices)) return null;
  if (!Array.isArray(value.selectedNeighborhoods)) return null;
  if (!value.selectedServices.every((item) => typeof item === "string")) {
    return null;
  }
  if (!value.selectedNeighborhoods.every((item) => typeof item === "string")) {
    return null;
  }

  return {
    name: value.name as string,
    headline: value.headline as string,
    bio: value.bio as string,
    yearsExperience: value.yearsExperience,
    whatsapp: value.whatsapp as string,
    instagram: value.instagram as string,
    youtube: value.youtube as string,
    selectedServices: [...(value.selectedServices as string[])],
    primaryService: value.primaryService as string,
    allJoinville: value.allJoinville,
    selectedNeighborhoods: [...(value.selectedNeighborhoods as string[])],
  };
}

export function parseProfessionalOnboardingState(
  raw: string,
): ProfessionalOnboardingState | null {
  try {
    const value: unknown = JSON.parse(raw);
    if (!isRecord(value) || value.version !== 1) return null;
    if (typeof value.initialized !== "boolean") return null;
    const profile = parseProfileDraft(value.profile);
    if (!profile || !isRecord(value.completion)) return null;

    const completion = value.completion;
    const completionKeys: OnboardingStepId[] = [
      "profile",
      "services",
      "portfolio",
      "verification",
    ];
    if (completionKeys.some((key) => !isNullableString(completion[key]))) {
      return null;
    }

    let portfolio: ProfessionalOnboardingState["portfolio"] = null;
    if (value.portfolio !== null) {
      if (!isRecord(value.portfolio)) return null;
      if (
        typeof value.portfolio.title !== "string" ||
        typeof value.portfolio.service !== "string" ||
        typeof value.portfolio.description !== "string" ||
        typeof value.portfolio.submittedAt !== "string"
      ) {
        return null;
      }
      portfolio = {
        title: value.portfolio.title,
        service: value.portfolio.service,
        description: value.portfolio.description,
        submittedAt: value.portfolio.submittedAt,
      };
    }

    if (
      value.verificationStatus !== "not_started" &&
      value.verificationStatus !== "submitted"
    ) {
      return null;
    }

    return {
      version: 1,
      initialized: value.initialized,
      profile,
      portfolio,
      verificationStatus: value.verificationStatus,
      completion: {
        profile: completion.profile as string | null,
        services: completion.services as string | null,
        portfolio: completion.portfolio as string | null,
        verification: completion.verification as string | null,
      },
    };
  } catch {
    return null;
  }
}

export function normalizeBrazilianPhone(phone: string) {
  const digits = phone.replace(/\D/g, "");
  return digits.startsWith("55") && digits.length >= 12
    ? digits.slice(2)
    : digits;
}

export function validateOnboardingProfile(
  draft: ProfessionalProfileDraft,
): OnboardingProfileErrors {
  const phone = normalizeBrazilianPhone(draft.whatsapp);
  return {
    name: draft.name.trim().length >= 3 ? "" : "Informe seu nome profissional.",
    whatsapp:
      phone.length === 10 || phone.length === 11
        ? ""
        : "Informe um WhatsApp brasileiro com DDD.",
    headline: draft.headline.trim()
      ? ""
      : "Escreva uma frase curta de apresentação.",
    bio: draft.bio.trim() ? "" : "Conte um pouco sobre o seu trabalho.",
  };
}

export function validateOnboardingServices(
  draft: ProfessionalProfileDraft,
): OnboardingServicesErrors {
  const hasServices =
    draft.selectedServices.length > 0 &&
    draft.selectedServices.includes(draft.primaryService);
  const hasCoverage =
    draft.allJoinville || draft.selectedNeighborhoods.length > 0;
  return {
    services: hasServices
      ? ""
      : "Escolha ao menos um serviço e defina o principal.",
    coverage: hasCoverage
      ? ""
      : "Selecione toda Joinville ou pelo menos um bairro.",
  };
}

export function validateOnboardingImage(
  file: File | null,
): OnboardingFileValidation {
  if (!file) {
    return { valid: false, error: "Selecione uma imagem JPG ou PNG." };
  }
  if (!["image/jpeg", "image/png"].includes(file.type)) {
    return { valid: false, error: "Use uma imagem no formato JPG ou PNG." };
  }
  if (file.size > onboardingImageMaxBytes) {
    return { valid: false, error: "A imagem deve ter no máximo 10 MB." };
  }
  return { valid: true, error: "" };
}

export function getOnboardingStepCompletion(
  state: ProfessionalOnboardingState,
): Record<OnboardingStepId, boolean> {
  const profileErrors = validateOnboardingProfile(state.profile);
  const servicesErrors = validateOnboardingServices(state.profile);
  return {
    profile:
      Boolean(state.completion.profile) &&
      Object.values(profileErrors).every((error) => !error),
    services:
      Boolean(state.completion.services) &&
      Object.values(servicesErrors).every((error) => !error),
    portfolio: Boolean(state.completion.portfolio && state.portfolio),
    verification: Boolean(
      state.completion.verification && state.verificationStatus === "submitted",
    ),
  };
}

export function calculateOnboardingProgress(
  completion: Record<OnboardingStepId, boolean>,
) {
  const completed = Object.values(completion).filter(Boolean).length;
  return completed * 25;
}

function cloneProfileDraft(
  draft: ProfessionalProfileDraft,
): ProfessionalProfileDraft {
  return {
    ...draft,
    selectedServices: [...draft.selectedServices],
    selectedNeighborhoods: [...draft.selectedNeighborhoods],
  };
}

export function useProfessionalOnboarding() {
  const state = useState<ProfessionalOnboardingState>(
    "professional-onboarding",
    createInitialProfessionalOnboardingState,
  );
  const hydrated = useState("professional-onboarding-hydrated", () => false);

  function persist() {
    if (!import.meta.client) return;
    window.localStorage.setItem(
      professionalOnboardingStorageKey,
      JSON.stringify(state.value),
    );
  }

  function hydrate() {
    if (hydrated.value) return;
    if (import.meta.client) {
      const stored = window.localStorage.getItem(
        professionalOnboardingStorageKey,
      );
      if (stored) {
        const parsed = parseProfessionalOnboardingState(stored);
        state.value = parsed ?? createInitialProfessionalOnboardingState();
      }
    }
    hydrated.value = true;
  }

  onMounted(hydrate);

  const stepCompletion = computed(() =>
    getOnboardingStepCompletion(state.value),
  );
  const progress = computed(() =>
    calculateOnboardingProgress(stepCompletion.value),
  );
  const isComplete = computed(() => progress.value === 100);
  const firstIncompleteStep = computed<OnboardingStepId>(() => {
    return (
      professionalOnboardingSteps.find((step) => !stepCompletion.value[step.id])
        ?.id ?? "verification"
    );
  });
  const checklist = computed<OnboardingChecklistItem[]>(() =>
    professionalOnboardingSteps.map((step) => ({
      ...step,
      done: stepCompletion.value[step.id],
      to: `/app/professional/onboarding?step=${step.id}`,
    })),
  );

  function initializeFromAuth(payload: { name: string; phone: string }) {
    hydrate();
    if (state.value.initialized) return;
    state.value = {
      ...state.value,
      initialized: true,
      profile: {
        ...state.value.profile,
        name: payload.name.trim(),
        whatsapp: normalizeBrazilianPhone(payload.phone),
      },
    };
    persist();
  }

  function completeProfile(draft: ProfessionalProfileDraft) {
    const errors = validateOnboardingProfile(draft);
    if (Object.values(errors).some(Boolean)) return false;
    const completedAt = new Date().toISOString();
    state.value = {
      ...state.value,
      profile: {
        ...cloneProfileDraft(draft),
        name: draft.name.trim(),
        whatsapp: normalizeBrazilianPhone(draft.whatsapp),
        headline: draft.headline.trim(),
        bio: draft.bio.trim(),
      },
      completion: {
        ...state.value.completion,
        profile: completedAt,
      },
    };
    persist();
    return true;
  }

  function completeServices(draft: ProfessionalProfileDraft) {
    const errors = validateOnboardingServices(draft);
    if (Object.values(errors).some(Boolean)) return false;
    const completedAt = new Date().toISOString();
    state.value = {
      ...state.value,
      profile: cloneProfileDraft(draft),
      completion: {
        ...state.value.completion,
        services: completedAt,
      },
    };
    persist();
    return true;
  }

  function completePortfolio(submission: OnboardingPortfolioSubmission) {
    const validation = validateOnboardingImage(submission.file);
    if (!validation.valid) return false;
    const completedAt = new Date().toISOString();
    state.value = {
      ...state.value,
      portfolio: {
        title: submission.title.trim(),
        service: submission.service,
        description: submission.description.trim(),
        submittedAt: completedAt,
      },
      completion: {
        ...state.value.completion,
        portfolio: completedAt,
      },
    };
    persist();
    return true;
  }

  function completeVerification(file: File) {
    const validation = validateOnboardingImage(file);
    if (!validation.valid) return false;
    const completedAt = new Date().toISOString();
    state.value = {
      ...state.value,
      verificationStatus: "submitted",
      completion: {
        ...state.value.completion,
        verification: completedAt,
      },
    };
    persist();
    return true;
  }

  function reset() {
    state.value = createInitialProfessionalOnboardingState();
    hydrated.value = true;
    if (import.meta.client) {
      window.localStorage.removeItem(professionalOnboardingStorageKey);
    }
  }

  return {
    state: readonly(state),
    hydrated: readonly(hydrated),
    stepCompletion,
    checklist,
    progress,
    isComplete,
    firstIncompleteStep,
    hydrate,
    initializeFromAuth,
    completeProfile,
    completeServices,
    completePortfolio,
    completeVerification,
    reset,
  };
}
