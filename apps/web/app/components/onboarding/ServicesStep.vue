<script setup lang="ts">
import { ref, shallowRef } from "vue";
import type { Neighborhood, ProfessionalProfileDraft, Service } from "~/types";
import { validateOnboardingServices } from "~/composables/useProfessionalOnboarding";

const props = defineProps<{
  draft: ProfessionalProfileDraft;
  services: Service[];
  neighborhoods: Neighborhood[];
  saving?: boolean;
  serverError?: string;
}>();
const emit = defineEmits<{
  back: [];
  complete: [draft: ProfessionalProfileDraft];
}>();

const form = ref<ProfessionalProfileDraft>({
  ...props.draft,
  selectedServices: [...props.draft.selectedServices],
  serviceNotes: { ...props.draft.serviceNotes },
  selectedNeighborhoods: [...props.draft.selectedNeighborhoods],
});
const error = shallowRef("");

function toggleService(name: string) {
  if (form.value.selectedServices.includes(name)) {
    if (form.value.selectedServices.length === 1) return;
    form.value.selectedServices = form.value.selectedServices.filter(
      (service) => service !== name,
    );
    if (form.value.primaryService === name) {
      form.value.primaryService = form.value.selectedServices[0] ?? "";
    }
  } else {
    form.value.selectedServices.push(name);
    if (!form.value.primaryService) form.value.primaryService = name;
  }
  error.value = "";
}

function toggleNeighborhood(name: string) {
  form.value.selectedNeighborhoods = form.value.selectedNeighborhoods.includes(
    name,
  )
    ? form.value.selectedNeighborhoods.filter((item) => item !== name)
    : [...form.value.selectedNeighborhoods, name];
  error.value = "";
}

function submit() {
  const errors = validateOnboardingServices(form.value);
  error.value = Object.values(errors).find(Boolean) ?? "";
  if (error.value) return;
  emit("complete", {
    ...form.value,
    selectedServices: [...form.value.selectedServices],
    serviceNotes: { ...form.value.serviceNotes },
    selectedNeighborhoods: [...form.value.selectedNeighborhoods],
  });
}
</script>

<template>
  <section aria-labelledby="onboarding-services-title">
    <header class="onboarding-step-heading">
      <DesignSystemEyebrow>Etapa 2 de 4</DesignSystemEyebrow>
      <h2 id="onboarding-services-title">Escolha o que você oferece.</h2>
      <p>
        Selecione ao menos um serviço e informe onde os clientes podem encontrar
        você.
      </p>
    </header>

    <form class="onboarding-step-form" @submit.prevent="submit">
      <p
        v-if="error || props.serverError"
        class="onboarding-step-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" />
        {{ error || props.serverError }}
      </p>
      <DashboardProfileFormLayout>
        <DashboardProfileServicesSection
          v-model="form"
          :services="services"
          @toggle="toggleService"
        />
        <DashboardProfileCoverageSection
          v-model="form"
          :neighborhoods="neighborhoods"
          @dirty="error = ''"
          @toggle="toggleNeighborhood"
        />
      </DashboardProfileFormLayout>
      <footer class="onboarding-step-actions">
        <UButton
          type="button"
          color="neutral"
          variant="ghost"
          icon="i-lucide-arrow-left"
          @click="$emit('back')"
        >
          Voltar
        </UButton>
        <UButton
          type="submit"
          color="primary"
          trailing-icon="i-lucide-arrow-right"
          :loading="props.saving"
          :disabled="props.saving"
        >
          Salvar e continuar
        </UButton>
      </footer>
    </form>
  </section>
</template>
