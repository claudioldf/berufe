import { computed, reactive, readonly, shallowRef, toValue, watch } from "vue";
import type { MaybeRefOrGetter } from "vue";
import type { Professional, ProfessionalProfileDraft } from "~/types";
import { normalizeBrazilianMobilePhone } from "~/utils/brazilian-phone";
import {
  normalizeSocialProfile,
  type SocialPlatform,
} from "~/utils/socialProfiles";
import {
  normalizePrimaryService,
  toggleProfessionalService,
} from "~/utils/services";

export interface ProfessionalProfileValidation {
  identity: {
    name: string;
    birthdate: string;
    whatsapp: string;
    headline: string;
    bio: string;
    yearsExperience: string;
  };
  social: Record<SocialPlatform, string>;
  services: string;
  coverage: string;
}

function isPlausibleBirthdate(value: string) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return false;

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const birthdate = new Date(year, month - 1, day);
  if (
    birthdate.getFullYear() !== year ||
    birthdate.getMonth() !== month - 1 ||
    birthdate.getDate() !== day
  ) {
    return false;
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const oldest = new Date(today);
  oldest.setFullYear(oldest.getFullYear() - 120);
  return birthdate >= oldest && birthdate <= today;
}

export function validateProfessionalProfileDraft(
  draft: ProfessionalProfileDraft,
): ProfessionalProfileValidation {
  const nameLength = draft.name.trim().length;
  const experience = draft.yearsExperience;
  const instagram = normalizeSocialProfile(draft.instagram, "instagram");
  const youtube = normalizeSocialProfile(draft.youtube, "youtube");
  const hasServices = draft.selectedServices.length > 0;
  const hasFeaturedService =
    draft.selectedServices.length === 1 ||
    draft.selectedServices.includes(draft.primaryService);
  const hasValidServiceNotes = draft.selectedServices.every(
    (service) => (draft.serviceNotes[service] ?? "").trim().length <= 120,
  );
  const hasCoverage =
    Boolean(draft.coverageCityCode) &&
    (draft.coversWholeCity || draft.selectedNeighborhoodCodes.length > 0);

  return {
    identity: {
      name:
        nameLength < 3
          ? "Informe um nome com pelo menos 3 caracteres."
          : nameLength > 70
            ? "Use no máximo 70 caracteres."
            : "",
      birthdate: isPlausibleBirthdate(draft.birthdate)
        ? ""
        : "Informe uma data de nascimento válida.",
      whatsapp:
        draft.whatsapp.trim() && !normalizeBrazilianMobilePhone(draft.whatsapp)
          ? "Informe um celular brasileiro válido com DDD."
          : "",
      headline:
        draft.headline.trim().length > 120
          ? "Use no máximo 120 caracteres."
          : "",
      bio:
        draft.bio.trim().length > 2500 ? "Use no máximo 2.500 caracteres." : "",
      yearsExperience:
        experience !== null &&
        experience !== undefined &&
        (!Number.isInteger(experience) || experience < 0 || experience > 70)
          ? "Informe um número inteiro entre 0 e 70."
          : "",
    },
    social: {
      instagram: instagram.error,
      youtube: youtube.error,
    },
    services: !hasServices
      ? "Escolha ao menos um serviço."
      : !hasFeaturedService
        ? "Escolha o serviço que deve aparecer em destaque."
        : !hasValidServiceNotes
          ? "Use até 120 caracteres nas especializações."
          : "",
    coverage: hasCoverage
      ? ""
      : "Selecione uma cidade inteira ou pelo menos um bairro dela.",
  };
}

function hasValidationErrors(validation: ProfessionalProfileValidation) {
  return [
    ...Object.values(validation.identity),
    ...Object.values(validation.social),
    validation.services,
    validation.coverage,
  ].some(Boolean);
}

function createDraft(professional: Professional): ProfessionalProfileDraft {
  const selectedServices = [...professional.services];

  return {
    name: professional.name,
    birthdate: professional.birthdate,
    headline: professional.headline,
    bio: professional.bio,
    yearsExperience: professional.yearsExperience,
    whatsapp: professional.whatsapp,
    instagram: professional.instagram ?? "",
    youtube: professional.youtube ?? "",
    selectedServices,
    serviceNotes: Object.fromEntries(
      professional.services.map((service, index) => [
        service,
        professional.serviceNotes[index] ?? "",
      ]),
    ),
    primaryService: normalizePrimaryService(
      selectedServices,
      professional.primaryService,
    ),
    coverageCityCode: professional.coverage.city?.code ?? "",
    coversWholeCity: professional.coverage.wholeCity,
    selectedNeighborhoodCodes: professional.coverage.neighborhoods.map(
      (neighborhood) => neighborhood.code,
    ),
  };
}

export function useProfessionalProfileDraft(
  source: MaybeRefOrGetter<Professional>,
) {
  const form = reactive<ProfessionalProfileDraft>(createDraft(toValue(source)));
  const saved = shallowRef(true);
  const socialErrors = reactive<Record<SocialPlatform, string>>({
    instagram: "",
    youtube: "",
  });
  const validation = computed(() => validateProfessionalProfileDraft(form));
  const isValid = computed(() => !hasValidationErrors(validation.value));

  function reset(professional = toValue(source)) {
    Object.assign(form, createDraft(professional));
    socialErrors.instagram = "";
    socialErrors.youtube = "";
    saved.value = true;
  }

  watch(
    () => toValue(source).id,
    () => reset(),
  );

  function markDirty() {
    saved.value = false;
  }

  function validateSocialField(platform: SocialPlatform) {
    const result = normalizeSocialProfile(form[platform], platform);
    socialErrors[platform] = result.error;
    return result;
  }

  function clearSocialError(platform: SocialPlatform) {
    socialErrors[platform] = "";
  }

  function toggleService(name: string) {
    if (
      form.selectedServices.includes(name) &&
      form.selectedServices.length === 1
    )
      return;

    if (form.selectedServices.includes(name)) {
      form.serviceNotes = Object.fromEntries(
        Object.entries(form.serviceNotes).filter(
          ([service]) => service !== name,
        ),
      );
    }

    const selection = toggleProfessionalService(
      form.selectedServices,
      form.primaryService,
      name,
    );
    form.selectedServices = selection.selectedServices;
    form.primaryService = selection.primaryService;
    markDirty();
  }

  function commit(): ProfessionalProfileDraft | null {
    const instagram = validateSocialField("instagram");
    const youtube = validateSocialField("youtube");
    if (instagram.error || youtube.error) return null;

    form.instagram = instagram.url;
    form.youtube = youtube.url;
    form.primaryService = normalizePrimaryService(
      form.selectedServices,
      form.primaryService,
    );
    return {
      ...form,
      selectedServices: [...form.selectedServices],
      selectedNeighborhoodCodes: [...form.selectedNeighborhoodCodes],
    };
  }

  function confirmSaved() {
    saved.value = true;
  }

  return {
    form,
    saved: readonly(saved),
    socialErrors: readonly(socialErrors),
    validation: readonly(validation),
    isValid: readonly(isValid),
    markDirty,
    validateSocialField,
    clearSocialError,
    toggleService,
    commit,
    confirmSaved,
    reset,
  };
}
