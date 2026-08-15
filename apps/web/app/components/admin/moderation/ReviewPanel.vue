<script setup lang="ts">
import type { ModerationQueueItem } from "~/types";

defineProps<{ item: ModerationQueueItem }>();
defineEmits<{ approve: []; reject: [] }>();
</script>

<template>
  <section class="moderation__review" aria-labelledby="moderation-item-title">
    <header>
      <div>
        <span>{{ item.type }}</span>
        <h2 id="moderation-item-title">{{ item.title }}</h2>
        <p>{{ item.subtitle }}</p>
      </div>
      <button type="button" aria-label="Mais opções">
        <UIcon name="i-lucide-ellipsis" />
      </button>
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
      <div>
        <UIcon
          :name="
            item.type === 'Verificação'
              ? 'i-lucide-file-lock-2'
              : 'i-lucide-scan-search'
          "
        />
      </div>
      <span>
        <small>Conteúdo enviado</small>
        <p>{{ item.preview }}</p>
      </span>
    </div>
    <div v-if="item.type === 'Verificação'" class="moderation__private-warning">
      <UIcon name="i-lucide-lock-keyhole" />
      <span>
        <strong>Acesso a arquivo restrito</strong>
        <small>
          A abertura do documento será registrada com seu usuário, horário e
          solicitação.
        </small>
      </span>
      <UButton size="sm" color="neutral" variant="outline">
        Abrir documento
      </UButton>
    </div>
    <DesignSystemFormField
      id="moderation-note"
      class="moderation__note"
      label="Nota interna opcional"
    >
      <textarea
        name="moderation-note"
        maxlength="500"
        placeholder="Adicione contexto para a trilha de auditoria…"
      />
    </DesignSystemFormField>
    <footer>
      <UButton
        color="error"
        variant="outline"
        icon="i-lucide-x"
        @click="$emit('reject')"
      >
        Rejeitar
      </UButton>
      <UButton color="primary" icon="i-lucide-check" @click="$emit('approve')">
        Aprovar e publicar
      </UButton>
    </footer>
  </section>
</template>
