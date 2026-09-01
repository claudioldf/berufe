<script setup lang="ts">
import { computed } from "vue";
import StatusTimelineCard from "~/components/dashboard/StatusTimelineCard.vue";
import type { ProfessionalServiceJob } from "~/types";

type StatusTone = "brand" | "warning" | "success" | "neutral";
type StepState = "done" | "current" | "upcoming";

const props = defineProps<{
  service: ProfessionalServiceJob;
  title: string;
  description: string;
  icon: string;
  tone: StatusTone;
}>();

const currentStep = computed(() => {
  if (props.service.status === "completed") return 1;
  return 0;
});

const progressSteps = computed<
  Array<{ label: string; description: string; state: StepState }>
>(() => {
  const steps = [
    { label: "Aprovado", description: "Aceito pelo cliente" },
    {
      label: "Concluído",
      description:
        props.service.status === "completed"
          ? "Registrado por você"
          : "Etapa final",
    },
  ];

  return steps.map((step, index) => ({
    ...step,
    state:
      props.service.status === "cancelled"
        ? "upcoming"
        : index < currentStep.value
          ? "done"
          : index === currentStep.value
            ? "current"
            : "upcoming",
  }));
});

const statusNote = computed(() => {
  if (props.service.customerFeedbackMessage) {
    return {
      label: "Mensagem do cliente",
      message: props.service.customerFeedbackMessage,
      icon: "i-lucide-message-circle",
      quoted: true,
      tone: "accent" as const,
    };
  }
  if (
    props.service.status === "cancelled" &&
    props.service.cancellationReason
  ) {
    return {
      label: "Motivo do cancelamento",
      message: props.service.cancellationReason,
      icon: "i-lucide-info",
      quoted: false,
      tone: "neutral" as const,
    };
  }
  return undefined;
});
</script>

<template>
  <StatusTimelineCard
    kicker="Status do serviço"
    :title="props.title"
    :description="props.description"
    :icon="props.icon"
    :tone="props.tone"
    :steps="progressSteps"
    progress-label="Etapas do serviço"
    :progress-muted="props.service.status === 'cancelled'"
    :note="statusNote"
  />
</template>
