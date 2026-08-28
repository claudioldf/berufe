import { computed, onMounted, readonly, shallowRef } from "vue";
import type {
  OnboardingChecklistItem,
  OnboardingCompletionState,
  OnboardingFileValidation,
  OnboardingProfileErrors,
  OnboardingServicesErrors,
  OnboardingStepDefinition,
  OnboardingStepId,
  ProfessionalOnboardingState,
  ProfessionalProfileDraft,
} from "~/types";
import { updateProfessionalIdentity } from "~/services/api/professional-workspace";
import { ApiRequestError } from "~/services/api/errors";
import { useApiClient } from "~/services/api/client";

interface ProfessionalOnboardingDependencies {
  saveIdentity?: (
    draft: ProfessionalProfileDraft,
  ) => Promise<ProfessionalProfileDraft>;
  saveSupply?: (
    draft: ProfessionalProfileDraft,
  ) => Promise<ProfessionalProfileDraft>;
  saveVerification?: (file: File) => Promise<{ submittedAt: string }>;
}

const legacyProfessionalOnboardingStorageKey =
  "berufe:professional-onboarding:v2";
export const onboardingImageMaxBytes = 10 * 1024 * 1024;

export const professionalOnboardingSteps: OnboardingStepDefinition[] = [
  {
    id: "profile",
    label: "Perfil e contato",
    description: "Nome, foto e data de nascimento",
    icon: "i-lucide-user-round",
  },
  {
    id: "services",
    label: "Serviços e cobertura",
    description: "O que você faz e onde atende",
    icon: "i-lucide-briefcase-business",
  },
  {
    id: "verification",
    label: "Verificação",
    description: "Opcional antes de publicar",
    icon: "i-lucide-shield-check",
  },
];

export function createEmptyProfessionalProfileDraft(): ProfessionalProfileDraft {
  return {
    name: "",
    birthdate: "",
    headline: "",
    bio: "",
    yearsExperience: 0,
    whatsapp: "",
    instagram: "",
    youtube: "",
    selectedServices: [],
    serviceNotes: {},
    primaryService: "",
    coverageCityCode: "",
    coversWholeCity: false,
    selectedNeighborhoodCodes: [],
  };
}

function createEmptyCompletionState(): OnboardingCompletionState {
  return {
    profile: null,
    services: null,
    verification: null,
  };
}

export function createInitialProfessionalOnboardingState(): ProfessionalOnboardingState {
  return {
    version: 2,
    initialized: false,
    profile: createEmptyProfessionalProfileDraft(),
    photoReady: false,
    verificationStatus: "not_started",
    completion: createEmptyCompletionState(),
  };
}

export function normalizeBrazilianPhone(phone: string) {
  const digits = phone.replace(/\D/g, "");
  return digits.startsWith("55") && digits.length >= 12
    ? digits.slice(2)
    : digits;
}

export function validateOnboardingProfile(
  draft: ProfessionalProfileDraft,
  photoReady = true,
): OnboardingProfileErrors {
  return {
    name: draft.name.trim().length >= 3 ? "" : "Informe seu nome profissional.",
    birthdate: /^\d{4}-\d{2}-\d{2}$/.test(draft.birthdate)
      ? ""
      : "Informe sua data de nascimento.",
    photo: photoReady ? "" : "Envie uma foto profissional para continuar.",
  };
}

export function validateOnboardingServices(
  draft: ProfessionalProfileDraft,
): OnboardingServicesErrors {
  const hasServices =
    draft.selectedServices.length > 0 &&
    draft.selectedServices.includes(draft.primaryService);
  const hasCoverage =
    Boolean(draft.coverageCityCode) &&
    (draft.coversWholeCity || draft.selectedNeighborhoodCodes.length > 0);
  return {
    services: hasServices
      ? ""
      : "Escolha ao menos um serviço e defina o principal.",
    coverage: hasCoverage
      ? ""
      : "Selecione uma cidade inteira ou pelo menos um bairro dela.",
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
  const profileErrors = validateOnboardingProfile(
    state.profile,
    state.photoReady,
  );
  const servicesErrors = validateOnboardingServices(state.profile);
  return {
    profile:
      Boolean(state.completion.profile) &&
      Object.values(profileErrors).every((error) => !error),
    services:
      Boolean(state.completion.services) &&
      Object.values(servicesErrors).every((error) => !error),
    verification: Boolean(
      state.completion.verification &&
      ["submitted", "skipped"].includes(state.verificationStatus),
    ),
  };
}

export function calculateOnboardingProgress(
  completion: Record<OnboardingStepId, boolean>,
) {
  const completed = Object.values(completion).filter(Boolean).length;
  return Math.round((completed / professionalOnboardingSteps.length) * 100);
}

function cloneProfileDraft(
  draft: ProfessionalProfileDraft,
): ProfessionalProfileDraft {
  return {
    ...draft,
    selectedServices: [...draft.selectedServices],
    serviceNotes: { ...draft.serviceNotes },
    selectedNeighborhoodCodes: [...draft.selectedNeighborhoodCodes],
  };
}

export function useProfessionalOnboarding(
  dependencies: ProfessionalOnboardingDependencies = {},
) {
  const state = useState<ProfessionalOnboardingState>(
    "professional-onboarding",
    createInitialProfessionalOnboardingState,
  );
  const hydrated = useState("professional-onboarding-hydrated", () => false);
  const profileSaving = shallowRef(false);
  const profileError = shallowRef("");
  const supplySaving = shallowRef(false);
  const supplyError = shallowRef("");
  const verificationSaving = shallowRef(false);
  const verificationError = shallowRef("");
  const apiClient = dependencies.saveIdentity ? undefined : useApiClient();
  const saveIdentity =
    dependencies.saveIdentity ??
    (async (draft: ProfessionalProfileDraft) => {
      const workspace = await updateProfessionalIdentity(apiClient!, draft);
      return {
        ...draft,
        ...workspace.profile.identity,
      };
    });
  const saveSupply =
    dependencies.saveSupply ??
    (async () => {
      throw new Error("Professional supply persistence is unavailable");
    });
  const saveVerification =
    dependencies.saveVerification ??
    (async () => {
      throw new Error("Professional verification persistence is unavailable");
    });

  function persist() {
    if (!import.meta.client) return;
    window.localStorage.removeItem(legacyProfessionalOnboardingStorageKey);
  }

  function hydrate() {
    if (hydrated.value) return;
    if (import.meta.client) {
      window.localStorage.removeItem(legacyProfessionalOnboardingStorageKey);
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

  function initializeFromWorkspace(
    identity: ProfessionalOnboardingState["profile"],
    photoReady: boolean,
    verificationSubmittedAt?: string | null,
  ) {
    hydrate();
    const complete = Object.values(
      validateOnboardingProfile(identity, photoReady),
    ).every((error) => !error);
    const servicesComplete = Object.values(
      validateOnboardingServices(identity),
    ).every((error) => !error);
    state.value = {
      ...state.value,
      initialized: true,
      profile: cloneProfileDraft(identity),
      photoReady,
      verificationStatus:
        verificationSubmittedAt === undefined
          ? state.value.verificationStatus
          : verificationSubmittedAt
            ? "submitted"
            : "not_started",
      completion: {
        ...state.value.completion,
        profile: complete
          ? (state.value.completion.profile ?? new Date().toISOString())
          : null,
        services: servicesComplete
          ? (state.value.completion.services ?? new Date().toISOString())
          : null,
        verification:
          verificationSubmittedAt === undefined
            ? state.value.completion.verification
            : verificationSubmittedAt,
      },
    };
    persist();
  }

  async function completeProfile(draft: ProfessionalProfileDraft) {
    const errors = validateOnboardingProfile(draft, state.value.photoReady);
    if (Object.values(errors).some(Boolean)) return false;
    if (profileSaving.value) return false;

    profileSaving.value = true;
    profileError.value = "";
    try {
      const savedProfile = await saveIdentity(draft);
      const completedAt = new Date().toISOString();
      state.value = {
        ...state.value,
        profile: {
          ...cloneProfileDraft(savedProfile),
          name: savedProfile.name.trim(),
          whatsapp: normalizeBrazilianPhone(savedProfile.whatsapp),
          headline: savedProfile.headline.trim(),
          bio: savedProfile.bio.trim(),
        },
        completion: {
          ...state.value.completion,
          profile: completedAt,
        },
      };
      persist();
      return true;
    } catch (error) {
      profileError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível salvar seu perfil agora. Tente novamente.";
      return false;
    } finally {
      profileSaving.value = false;
    }
  }

  async function completeServices(draft: ProfessionalProfileDraft) {
    const errors = validateOnboardingServices(draft);
    if (Object.values(errors).some(Boolean)) return false;
    if (supplySaving.value) return false;

    supplySaving.value = true;
    supplyError.value = "";
    try {
      const savedProfile = await saveSupply(draft);
      const completedAt = new Date().toISOString();
      state.value = {
        ...state.value,
        profile: cloneProfileDraft(savedProfile),
        completion: {
          ...state.value.completion,
          services: completedAt,
        },
      };
      persist();
      return true;
    } catch (error) {
      supplyError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível salvar os serviços agora. Tente novamente.";
      return false;
    } finally {
      supplySaving.value = false;
    }
  }

  async function completeVerification(file: File) {
    const validation = validateOnboardingImage(file);
    if (!validation.valid) return false;
    if (verificationSaving.value) return false;

    verificationSaving.value = true;
    verificationError.value = "";
    try {
      const saved = await saveVerification(file);
      state.value = {
        ...state.value,
        verificationStatus: "submitted",
        completion: {
          ...state.value.completion,
          verification: saved.submittedAt,
        },
      };
      persist();
      return true;
    } catch (error) {
      verificationError.value =
        error instanceof ApiRequestError
          ? error.message
          : "Não foi possível enviar a identidade agora. Tente novamente.";
      return false;
    } finally {
      verificationSaving.value = false;
    }
  }

  function skipVerification() {
    state.value = {
      ...state.value,
      verificationStatus: "skipped",
      completion: {
        ...state.value.completion,
        verification: new Date().toISOString(),
      },
    };
    persist();
  }

  function markPhotoReady() {
    state.value = { ...state.value, photoReady: true };
    persist();
  }

  function reset() {
    state.value = createInitialProfessionalOnboardingState();
    hydrated.value = true;
    if (import.meta.client) {
      window.localStorage.removeItem(legacyProfessionalOnboardingStorageKey);
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
    initializeFromWorkspace,
    completeProfile,
    completeServices,
    completeVerification,
    skipVerification,
    markPhotoReady,
    profileSaving: readonly(profileSaving),
    profileError: readonly(profileError),
    supplySaving: readonly(supplySaving),
    supplyError: readonly(supplyError),
    verificationSaving: readonly(verificationSaving),
    verificationError: readonly(verificationError),
    reset,
  };
}
