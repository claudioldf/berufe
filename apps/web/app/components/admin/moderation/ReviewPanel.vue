<script setup lang="ts">
import type { ModerationQueueItem } from "~/types";

defineProps<{
  item: ModerationQueueItem;
  note: string;
  evidenceLoading?: boolean;
  mutating?: boolean;
  identityMatchConfirmed?: boolean;
}>();
defineEmits<{
  approve: [];
  reject: [];
  openEvidence: [];
  note: [value: string];
  identityMatch: [value: boolean];
}>();
</script>

<template>
  <section class="moderation__review" aria-labelledby="moderation-item-title">
    <header>
      <div>
        <span>Verificação de identidade</span>
        <h2 id="moderation-item-title">{{ item.title }}</h2>
        <p>{{ item.subtitle }}</p>
      </div>
    </header>
    <div class="moderation__meta">
      <span
        ><UIcon name="i-lucide-clock-3" /> Enviado {{ item.submittedAt }}</span
      >
      <span><UIcon name="i-lucide-fingerprint" /> {{ item.id }}</span>
    </div>
    <div class="moderation__review-block">
      <span>Contexto da análise</span>
      <p>{{ item.details }}</p>
    </div>
    <div class="moderation__preview">
      <div><UIcon name="i-lucide-file-lock-2" /></div>
      <span>
        <small>Documento enviado</small>
        <p>{{ item.preview }}</p>
      </span>
    </div>
    <div class="moderation__private-warning">
      <UIcon name="i-lucide-lock-keyhole" />
      <span>
        <strong>Acesso a arquivo restrito</strong>
        <small>
          A abertura do documento será registrada com seu usuário, horário e
          solicitação.
        </small>
      </span>
      <UButton
        size="sm"
        color="neutral"
        variant="outline"
        :loading="evidenceLoading"
        :disabled="!item.verificationFileId"
        @click="$emit('openEvidence')"
      >
        {{
          item.verificationFileId ? "Abrir documento" : "Documento indisponível"
        }}
      </UButton>
    </div>
    <label
      v-if="item.status === 'pending_review'"
      class="moderation__identity-match"
    >
      <input
        type="checkbox"
        :checked="identityMatchConfirmed"
        @change="
          $emit('identityMatch', ($event.target as HTMLInputElement).checked)
        "
      />
      <span>
        Confirmo que a identidade e a data de nascimento
        <strong>{{ item.claimedBirthdate ?? "não informada" }}</strong>
        correspondem ao perfil.
      </span>
    </label>
    <DesignSystemFormField
      v-if="item.status === 'pending_review'"
      id="moderation-note"
      class="moderation__note"
      label="Nota interna opcional"
    >
      <textarea
        id="moderation-note"
        name="moderation-note"
        autocomplete="off"
        :value="note"
        maxlength="500"
        placeholder="Adicione contexto para a trilha de auditoria…"
        @input="$emit('note', ($event.target as HTMLTextAreaElement).value)"
      />
    </DesignSystemFormField>
    <footer v-if="item.status === 'pending_review'">
      <DesignSystemDisabledTooltip
        :reason="mutating ? 'Aguarde a decisão anterior' : null"
      >
        <UButton
          class="moderation__decision moderation__decision--reject"
          color="error"
          variant="outline"
          icon="i-lucide-x"
          :disabled="mutating"
          @click="$emit('reject')"
        >
          Rejeitar
        </UButton>
      </DesignSystemDisabledTooltip>
      <DesignSystemDisabledTooltip
        :reason="
          !mutating && !identityMatchConfirmed
            ? 'Confirme a identidade no checkbox acima'
            : null
        "
      >
        <UButton
          class="moderation__decision moderation__decision--approve"
          color="primary"
          icon="i-lucide-check"
          :loading="mutating"
          :disabled="mutating || !identityMatchConfirmed"
          @click="$emit('approve')"
        >
          Aprovar identidade
        </UButton>
      </DesignSystemDisabledTooltip>
    </footer>
  </section>
</template>
