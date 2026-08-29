<script setup lang="ts">
const open = defineModel<boolean>("open", { required: true });
const reason = defineModel<string>("reason", { required: true });
defineProps<{ displayName: string | null }>();
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
        hint="Motivo privado, visível apenas na trilha de auditoria."
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
          placeholder="Explique por que este perfil está sendo despublicado…"
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
        Confirmar despublicação
      </UButton>
    </template>
  </UModal>
</template>
