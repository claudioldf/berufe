<script setup lang="ts">
import type { ModerationQueueItem } from "~/types";

const props = defineProps<{
  item: ModerationQueueItem;
  note: string;
  mediaUrl?: string;
  mediaLoading?: boolean;
  mediaError?: string;
  mutating?: boolean;
}>();
const emit = defineEmits<{
  approve: [];
  reject: [];
  hide: [];
  restore: [];
  openEvidence: [];
  note: [value: string];
}>();

function toggleVisibility() {
  if (props.item.status === "hidden") emit("restore");
  else emit("hide");
}
</script>

<template>
  <section class="moderation__review" aria-labelledby="moderation-item-title">
    <header>
      <div>
        <span>{{ item.type }}</span>
        <h2 id="moderation-item-title">{{ item.title }}</h2>
        <p>{{ item.subtitle }}</p>
      </div>
      <UPopover v-if="item.status === 'approved' || item.status === 'hidden'">
        <button type="button" aria-label="Mais opções">
          <UIcon name="i-lucide-ellipsis" />
        </button>
        <template #content>
          <button
            class="moderation__overflow-action"
            type="button"
            :disabled="mutating"
            @click="toggleVisibility"
          >
            <UIcon
              :name="
                item.status === 'hidden' ? 'i-lucide-eye' : 'i-lucide-eye-off'
              "
            />
            {{ item.status === "hidden" ? "Restaurar" : "Ocultar" }}
          </button>
        </template>
      </UPopover>
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
    <div class="moderation__preview" :class="{ 'has-image': mediaUrl }">
      <img
        v-if="mediaUrl"
        :src="mediaUrl"
        :alt="`Conteúdo enviado para análise: ${item.title}`"
      />
      <div v-else>
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
        <p v-if="mediaLoading">Abrindo imagem privada…</p>
        <p v-else-if="mediaError">{{ mediaError }}</p>
        <p v-else>{{ item.preview }}</p>
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
      <UButton
        size="sm"
        color="neutral"
        variant="outline"
        @click="$emit('openEvidence')"
      >
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
        :value="note"
        maxlength="500"
        placeholder="Adicione contexto para a trilha de auditoria…"
        @input="$emit('note', ($event.target as HTMLTextAreaElement).value)"
      />
    </DesignSystemFormField>
    <footer v-if="item.status === 'pending_review'">
      <UButton
        color="error"
        variant="outline"
        icon="i-lucide-x"
        :disabled="mutating"
        @click="$emit('reject')"
      >
        Rejeitar
      </UButton>
      <UButton
        color="primary"
        icon="i-lucide-check"
        :loading="mutating"
        @click="$emit('approve')"
      >
        Aprovar e publicar
      </UButton>
    </footer>
  </section>
</template>
