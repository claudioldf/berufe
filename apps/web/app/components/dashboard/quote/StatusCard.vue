<script setup lang="ts">
import { computed } from "vue";
import StatusTimelineCard from "~/components/dashboard/StatusTimelineCard.vue";
import type { Quote } from "~/types";

type StepState = "done" | "current" | "upcoming";

const props = defineProps<{
  quote: Quote;
}>();

const statusPresentation = computed(() => {
  switch (props.quote.status) {
    case "saved":
      return {
        title: "Pronto para enviar",
        description:
          "O orçamento está salvo. Envie ao cliente quando estiver pronto.",
        icon: "i-lucide-cloud-check",
        tone: "brand" as const,
      };
    case "shared":
      return {
        title: "Aguardando resposta do cliente",
        description:
          "O cliente já pode revisar o orçamento pelo link compartilhado.",
        icon: "i-lucide-clock-3",
        tone: "warning" as const,
      };
    case "change_requested":
      return {
        title: "Alterações solicitadas",
        description:
          "Revise o pedido do cliente, ajuste o orçamento e envie uma nova versão.",
        icon: "i-lucide-circle-alert",
        tone: "warning" as const,
      };
    case "approved":
      return {
        title: "Orçamento aprovado",
        description:
          "O cliente aceitou esta proposta. Acompanhe agora na área de serviços.",
        icon: "i-lucide-check-circle-2",
        tone: "success" as const,
      };
    case "declined":
      return {
        title: "Orçamento recusado",
        description:
          "O cliente recusou esta versão. Você ainda pode revisar e enviar uma nova proposta.",
        icon: "i-lucide-x",
        tone: "danger" as const,
      };
    case "completed":
      return {
        title: "Orçamento concluído",
        description: "O serviço deste orçamento foi marcado como concluído.",
        icon: "i-lucide-badge-check",
        tone: "success" as const,
      };
    case "cancelled":
      return {
        title: "Orçamento cancelado",
        description:
          "O serviço aprovado foi cancelado e este orçamento foi encerrado.",
        icon: "i-lucide-ban",
        tone: "danger" as const,
      };
    case "draft":
    default:
      return {
        title: props.quote.id
          ? "Orçamento em rascunho"
          : "Comece seu orçamento",
        description: props.quote.id
          ? "Continue preenchendo os dados e salve quando quiser voltar depois."
          : "Preencha os dados para criar uma proposta clara para o cliente.",
        icon: "i-lucide-pencil",
        tone: "brand" as const,
      };
  }
});

const currentStep = computed(() => {
  if (props.quote.status === "completed") return 3;
  if (["approved", "cancelled"].includes(props.quote.status)) return 2;
  if (["shared", "change_requested", "declined"].includes(props.quote.status)) {
    return 1;
  }
  return 0;
});

const progressSteps = computed<
  Array<{ label: string; description: string; state: StepState }>
>(() => {
  const sent = [
    "shared",
    "change_requested",
    "approved",
    "declined",
    "completed",
    "cancelled",
  ].includes(props.quote.status);
  const approved = ["approved", "completed", "cancelled"].includes(
    props.quote.status,
  );
  const steps = [
    {
      label: "Rascunho",
      description:
        props.quote.status === "draft"
          ? props.quote.id
            ? "Salvo por você"
            : "Em preenchimento"
          : "Preparado por você",
    },
    {
      label: "Enviado",
      description: sent ? "Link enviado ao cliente" : "Próxima etapa",
    },
    {
      label: "Aprovado",
      description: approved ? "Aceito pelo cliente" : "Decisão do cliente",
    },
    {
      label: "Concluído",
      description:
        props.quote.status === "completed"
          ? "Serviço finalizado"
          : props.quote.status === "cancelled"
            ? "Serviço cancelado"
            : "Conclusão do serviço",
    },
  ];

  return steps.map((step, index) => ({
    ...step,
    state:
      props.quote.status === "declined"
        ? index < 2
          ? "done"
          : "upcoming"
        : props.quote.status === "cancelled"
          ? index < 3
            ? "done"
            : "upcoming"
          : index < currentStep.value
            ? "done"
            : index === currentStep.value
              ? "current"
              : "upcoming",
  }));
});

const statusNote = computed(() => {
  const message =
    props.quote.status === "change_requested"
      ? (props.quote.changeRequests[0]?.message ??
        props.quote.customerDecisionMessage)
      : props.quote.status === "declined"
        ? props.quote.customerDecisionMessage
        : "";
  if (!message) return undefined;

  return {
    label:
      props.quote.status === "change_requested"
        ? "Pedido do cliente"
        : "Mensagem do cliente",
    message,
    icon: "i-lucide-message-circle",
    tone: "accent" as const,
    quoted: true,
  };
});
</script>

<template>
  <StatusTimelineCard
    kicker="Status do orçamento"
    :title="statusPresentation.title"
    :description="statusPresentation.description"
    :icon="statusPresentation.icon"
    :tone="statusPresentation.tone"
    :steps="progressSteps"
    progress-label="Etapas do orçamento"
    :progress-muted="['declined', 'cancelled'].includes(props.quote.status)"
    :note="statusNote"
  />
</template>
