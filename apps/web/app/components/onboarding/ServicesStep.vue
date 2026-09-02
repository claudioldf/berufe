<script setup lang="ts">
import { computed, ref, useTemplateRef } from "vue";
import type { ProfessionalProfileDraft, Service } from "~/types";
import { validateOnboardingServices } from "~/composables/useProfessionalOnboarding";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";
import {
  normalizePrimaryService,
  toggleProfessionalService,
} from "~/utils/services";

const props = defineProps<{
  draft: ProfessionalProfileDraft;
  services: Service[];
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
  primaryService: normalizePrimaryService(
    props.draft.selectedServices,
    props.draft.primaryService,
  ),
  serviceNotes: { ...props.draft.serviceNotes },
  selectedNeighborhoodCodes: [...props.draft.selectedNeighborhoodCodes],
});
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const validation = computed(() => validateOnboardingServices(form.value));
const isValid = computed(() =>
  Object.values(validation.value).every((fieldError) => !fieldError),
);
const { validationAttempted, revealValidation } =
  useInlineFormValidation(formRoot);
const displayedErrors = computed(() =>
  validationAttempted.value ? validation.value : undefined,
);
const error = computed(
  () =>
    (validationAttempted.value
      ? Object.values(validation.value).find(Boolean)
      : "") ?? "",
);
const savingReason = computed(() =>
  props.saving ? "Aguarde o salvamento desta etapa terminar." : null,
);

function toggleService(name: string) {
  if (
    form.value.selectedServices.includes(name) &&
    form.value.selectedServices.length === 1
  )
    return;

  const selection = toggleProfessionalService(
    form.value.selectedServices,
    form.value.primaryService,
    name,
  );
  form.value.selectedServices = selection.selectedServices;
  form.value.primaryService = selection.primaryService;
}

function submit() {
  if (!revealValidation(isValid.value)) return;
  emit("complete", {
    ...form.value,
    selectedServices: [...form.value.selectedServices],
    serviceNotes: { ...form.value.serviceNotes },
    selectedNeighborhoodCodes: [...form.value.selectedNeighborhoodCodes],
  });
}
</script>

<template>
  <section aria-labelledby="onboarding-services-title">
    <header class="onboarding-step-heading">
      <DesignSystemEyebrow>Etapa 2 de 3</DesignSystemEyebrow>
      <h2 id="onboarding-services-title">Escolha o que você oferece.</h2>
      <p>
        Selecione ao menos um serviço e informe onde os clientes podem encontrar
        você.
      </p>
    </header>

    <form
      ref="formRoot"
      class="onboarding-step-form"
      novalidate
      @submit.prevent="submit"
    >
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
          :error="displayedErrors?.services"
          @toggle="toggleService"
        />
        <DashboardProfileCoverageSection
          v-model="form"
          :error="displayedErrors?.coverage"
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
        <DesignSystemDisabledTooltip
          :reason="savingReason"
          :loading="props.saving"
        >
          <UButton
            type="submit"
            color="primary"
            trailing-icon="i-lucide-arrow-right"
            :loading="props.saving"
            :disabled="props.saving"
          >
            Salvar e continuar
          </UButton>
        </DesignSystemDisabledTooltip>
      </footer>
    </form>
  </section>
</template>
