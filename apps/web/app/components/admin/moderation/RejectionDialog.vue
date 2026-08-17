<script setup lang="ts">
const open = defineModel<boolean>("open", { required: true });
const reason = defineModel<string>("reason", { required: true });
defineProps<{ action: "rejected" | "hidden" }>();
defineEmits<{ confirm: [] }>();
</script>

<template>
  <UModal
    v-model:open="open"
    :title="action === 'hidden' ? 'Ocultar conteúdo' : 'Rejeitar conteúdo'"
    description="A justificativa será privada e ficará visível ao profissional quando aplicável."
  >
    <template #body>
      <DesignSystemFormField
        id="rejection-reason"
        class="rejection-form"
        :label="
          action === 'hidden' ? 'Motivo da ocultação' : 'Motivo da rejeição'
        "
        :hint="`${reason.length}/500`"
        required
      >
        <textarea
          v-model="reason"
          name="rejection-reason"
          required
          minlength="10"
          maxlength="500"
          placeholder="Explique o que precisa ser corrigido…"
        />
      </DesignSystemFormField>
    </template>
    <template #footer>
      <UButton color="neutral" variant="ghost" @click="open = false">
        Cancelar
      </UButton>
      <UButton
        color="error"
        :disabled="reason.length < 10"
        @click="$emit('confirm')"
      >
        {{ action === "hidden" ? "Confirmar ocultação" : "Confirmar rejeição" }}
      </UButton>
    </template>
  </UModal>
</template>
