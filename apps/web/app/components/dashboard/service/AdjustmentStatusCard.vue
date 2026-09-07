<script setup lang="ts">
import { computed } from "vue";
import StatusTimelineCard from "~/components/dashboard/StatusTimelineCard.vue";
import type { ServiceAdjustment } from "~/types";

type StepState = "done" | "current" | "upcoming";

const props = defineProps<{
  adjustment?: ServiceAdjustment;
}>();

const status = computed(() => props.adjustment?.status ?? "draft");
const statusPresentation = computed(() => {
  switch (status.value) {
    case "awaiting_response":
      return {
        title: "Aguardando resposta do cliente",
        description:
          "O cliente já pode revisar este ajuste pelo link compartilhado.",
        icon: "i-lucide-clock-3",
        tone: "warning" as const,
      };
    case "change_requested":
      return {
        title: "Alterações solicitadas",
        description:
          "Revise o pedido do cliente, atualize o ajuste e envie novamente.",
        icon: "i-lucide-circle-alert",
        tone: "warning" as const,
      };
    case "approved":
      return {
        title: "Ajuste aprovado",
        description:
          "O valor foi aceito e já faz parte do total combinado do serviço.",
        icon: "i-lucide-check-circle-2",
        tone: "success" as const,
      };
    case "declined":
      return {
        title: "Ajuste recusado",
        description:
          "O cliente recusou esta revisão e o valor não foi incorporado ao serviço.",
        icon: "i-lucide-x",
        tone: "danger" as const,
      };
    case "cancelled":
      return {
        title: "Ajuste cancelado",
        description:
          "Este ajuste foi encerrado e não altera o acordo atual do serviço.",
        icon: "i-lucide-ban",
        tone: "neutral" as const,
      };
    case "draft":
    default:
      return {
        title: props.adjustment ? "Ajuste em rascunho" : "Comece seu ajuste",
        description: props.adjustment
          ? "Continue preenchendo os dados e salve quando quiser voltar depois."
          : "Registre o que mudou para apresentar uma proposta clara ao cliente.",
        icon: "i-lucide-pencil",
        tone: "brand" as const,
      };
  }
});

const currentStep = computed(() => {
  if (status.value === "approved") return 2;
  if (
    ["awaiting_response", "change_requested", "declined"].includes(status.value)
  ) {
    return 1;
  }
  return 0;
});
const progressSteps = computed<
  Array<{ label: string; description: string; state: StepState }>
>(() => {
  const shared = [
    "awaiting_response",
    "change_requested",
    "approved",
    "declined",
  ].includes(status.value);
  const approved = status.value === "approved";
  const steps = [
    {
      label: "Rascunho",
      description: props.adjustment ? "Salvo por você" : "Em preenchimento",
    },
    {
      label: "Enviado",
      description: shared ? "Link enviado ao cliente" : "Próxima etapa",
    },
    {
      label: "Aprovado",
      description: approved ? "Aceito pelo cliente" : "Decisão do cliente",
    },
  ];

  return steps.map((step, index) => ({
    ...step,
    state:
      status.value === "cancelled"
        ? "upcoming"
        : index < currentStep.value
          ? "done"
          : index === currentStep.value
            ? "current"
            : "upcoming",
  }));
});
const statusNote = computed(() => {
  if (status.value !== "change_requested") return undefined;
  const request = props.adjustment?.changeRequests.at(-1);
  if (!request?.message) return undefined;
  return {
    label: "Pedido do cliente",
    message: request.message,
    icon: "i-lucide-message-circle",
    tone: "accent" as const,
    quoted: true,
  };
});
</script>

<template>
  <StatusTimelineCard
    kicker="Status do ajuste"
    :title="statusPresentation.title"
    :description="statusPresentation.description"
    :icon="statusPresentation.icon"
    :tone="statusPresentation.tone"
    :steps="progressSteps"
    progress-label="Etapas do ajuste"
    :progress-muted="['declined', 'cancelled'].includes(status)"
    :note="statusNote"
  />
</template>
