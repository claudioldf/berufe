<script setup lang="ts">
const open = defineModel<boolean>("open", { required: true });
const reason = defineModel<string>("reason", { required: true });
defineProps<{ displayName: string | null; submitting?: boolean }>();
defineEmits<{ confirm: [] }>();
</script>

<template>
  <UModal
    v-model:open="open"
    title="Despublicar perfil"
    :description="`O perfil de ${displayName ?? 'este profissional'} deixará de aparecer nas buscas públicas.`"
  >
    <template #body>
      <DesignSystemFormField
        id="unpublish-reason"
        class="unpublish-form"
        label="Motivo da despublicação"
        hint="O motivo será exibido ao profissional e registrado na trilha de auditoria."
        required
      >
        <textarea
          id="unpublish-reason"
          v-model="reason"
          name="unpublish-reason"
          autocomplete="off"
          required
          minlength="10"
          maxlength="500"
          :disabled="submitting"
          placeholder="Explique por que este perfil está sendo despublicado…"
        />
      </DesignSystemFormField>
    </template>
    <template #footer>
      <UButton
        color="neutral"
        variant="ghost"
        :disabled="submitting"
        @click="open = false"
      >
        Cancelar
      </UButton>
      <DesignSystemDisabledTooltip
        :reason="
          !submitting && reason.trim().length < 10
            ? 'Escreva ao menos 10 caracteres explicando o motivo'
            : null
        "
        :loading="submitting"
      >
        <UButton
          color="error"
          :loading="submitting"
          :disabled="submitting || reason.trim().length < 10"
          @click="$emit('confirm')"
        >
          Confirmar despublicação
        </UButton>
      </DesignSystemDisabledTooltip>
    </template>
  </UModal>
</template>
