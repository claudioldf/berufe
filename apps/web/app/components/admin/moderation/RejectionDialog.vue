<script setup lang="ts">
const open = defineModel<boolean>("open", { required: true });
const reason = defineModel<string>("reason", { required: true });
defineEmits<{ confirm: [] }>();
</script>

<template>
  <UModal
    v-model:open="open"
    title="Rejeitar verificação de identidade"
    description="A justificativa ficará visível ao profissional para orientar um novo envio."
  >
    <template #body>
      <DesignSystemFormField
        id="rejection-reason"
        class="rejection-form"
        label="Motivo da rejeição"
        :hint="`${reason.length}/500`"
        required
      >
        <textarea
          id="rejection-reason"
          v-model="reason"
          name="rejection-reason"
          autocomplete="off"
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
      <DesignSystemDisabledTooltip
        :reason="
          reason.trim().length < 10
            ? 'Escreva ao menos 10 caracteres explicando o motivo'
            : null
        "
      >
        <UButton
          color="error"
          :disabled="reason.trim().length < 10"
          @click="$emit('confirm')"
        >
          Confirmar rejeição
        </UButton>
      </DesignSystemDisabledTooltip>
    </template>
  </UModal>
</template>
