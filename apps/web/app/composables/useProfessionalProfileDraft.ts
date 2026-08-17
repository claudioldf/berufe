import { reactive, readonly, shallowRef, toValue, watch } from "vue";
import type { MaybeRefOrGetter } from "vue";
import type { Professional, ProfessionalProfileDraft } from "~/types";
import {
  normalizeSocialProfile,
  type SocialPlatform,
} from "~/utils/socialProfiles";

function createDraft(professional: Professional): ProfessionalProfileDraft {
  return {
    name: professional.name,
    headline: professional.headline,
    bio: professional.bio,
    yearsExperience: professional.yearsExperience,
    whatsapp: professional.whatsapp,
    instagram: professional.instagram ?? "",
    youtube: professional.youtube ?? "",
    selectedServices: [...professional.services],
    primaryService: professional.primaryService,
    allJoinville: professional.allJoinville,
    selectedNeighborhoods: [...professional.neighborhoods],
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
    if (form.selectedServices.includes(name)) {
      if (form.selectedServices.length === 1) return;
      form.selectedServices = form.selectedServices.filter(
        (item) => item !== name,
      );
      if (form.primaryService === name) {
        form.primaryService = form.selectedServices[0] ?? "";
      }
    } else {
      form.selectedServices.push(name);
    }
    markDirty();
  }

  function toggleNeighborhood(name: string) {
    form.selectedNeighborhoods = form.selectedNeighborhoods.includes(name)
      ? form.selectedNeighborhoods.filter((item) => item !== name)
      : [...form.selectedNeighborhoods, name];
    markDirty();
  }

  function commit(): ProfessionalProfileDraft | null {
    const instagram = validateSocialField("instagram");
    const youtube = validateSocialField("youtube");
    if (instagram.error || youtube.error) return null;

    form.instagram = instagram.url;
    form.youtube = youtube.url;
    return {
      ...form,
      selectedServices: [...form.selectedServices],
      selectedNeighborhoods: [...form.selectedNeighborhoods],
    };
  }

  function confirmSaved() {
    saved.value = true;
  }

  return {
    form,
    saved: readonly(saved),
    socialErrors: readonly(socialErrors),
    markDirty,
    validateSocialField,
    clearSocialError,
    toggleService,
    toggleNeighborhood,
    commit,
    confirmSaved,
    reset,
  };
}
