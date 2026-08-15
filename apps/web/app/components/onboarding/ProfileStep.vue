<script setup lang="ts">
import { ref, shallowRef } from "vue";
import type { ProfessionalProfileDraft } from "~/types";
import { validateOnboardingProfile } from "~/composables/useProfessionalOnboarding";

const props = defineProps<{ draft: ProfessionalProfileDraft }>();
const emit = defineEmits<{
  complete: [draft: ProfessionalProfileDraft];
}>();

const form = ref<ProfessionalProfileDraft>({
  ...props.draft,
  selectedServices: [...props.draft.selectedServices],
  selectedNeighborhoods: [...props.draft.selectedNeighborhoods],
});
const error = shallowRef("");

function submit() {
  const errors = validateOnboardingProfile(form.value);
  error.value = Object.values(errors).find(Boolean) ?? "";
  if (error.value) return;
  emit("complete", {
    ...form.value,
    selectedServices: [...form.value.selectedServices],
    selectedNeighborhoods: [...form.value.selectedNeighborhoods],
  });
}
</script>

<template>
  <section aria-labelledby="onboarding-profile-title">
    <header class="onboarding-step-heading">
      <DesignSystemEyebrow>Etapa 1 de 4</DesignSystemEyebrow>
      <h2 id="onboarding-profile-title">Conte como você trabalha.</h2>
      <p>
        Essas informações ajudam clientes a entender rapidamente quem você é e
        como entrar em contato.
      </p>
    </header>

    <form class="onboarding-step-form" @submit.prevent="submit">
      <p v-if="error" class="onboarding-step-error" role="alert">
        <UIcon name="i-lucide-circle-alert" /> {{ error }}
      </p>
      <DashboardProfileFormLayout>
        <DashboardProfileIdentitySection v-model="form" />
      </DashboardProfileFormLayout>
      <footer class="onboarding-step-actions onboarding-step-actions--end">
        <UButton
          type="submit"
          color="primary"
          trailing-icon="i-lucide-arrow-right"
        >
          Salvar e continuar
        </UButton>
      </footer>
    </form>
  </section>
</template>
