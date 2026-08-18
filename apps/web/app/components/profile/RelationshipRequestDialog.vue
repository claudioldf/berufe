<script setup lang="ts">
import { computed, shallowRef, watch } from "vue";
import type {
  ProfessionalRelationshipRequestInput,
  ProfessionalRelationshipType,
} from "~/services/api/professional-relationships";

const open = defineModel<boolean>("open", { required: true });
const props = defineProps<{
  recipientProfessionalId: string;
  recipientName: string;
  submitting: boolean;
  error?: string;
}>();
const emit = defineEmits<{
  submit: [input: ProfessionalRelationshipRequestInput];
}>();

const relationshipType =
  shallowRef<ProfessionalRelationshipType>("recommendation");
const contextNote = shallowRef("");
const noteLength = computed(() => contextNote.value.length);

watch(open, (isOpen) => {
  if (isOpen) return;

  relationshipType.value = "recommendation";
  contextNote.value = "";
});

function submit() {
  emit("submit", {
    recipientProfessionalId: props.recipientProfessionalId,
    relationshipType: relationshipType.value,
    contextNote: contextNote.value,
  });
}
</script>

<template>
  <UModal
    v-model:open="open"
    title="Solicitar relação profissional"
    :description="`A solicitação será enviada para ${recipientName} confirmar antes da moderação.`"
  >
    <template #body>
      <form class="relationship-form" @submit.prevent="submit">
        <DesignSystemFormField
          id="relationship-type"
          label="Tipo de relação"
          required
        >
          <select
            id="relationship-type"
            v-model="relationshipType"
            name="relationship-type"
            required
          >
            <option value="recommendation">Recomendo este profissional</option>
            <option value="worked_together">Trabalhamos juntos</option>
          </select>
        </DesignSystemFormField>

        <DesignSystemFormField
          id="relationship-context"
          label="Contexto"
          :hint="`${noteLength}/300 · Opcional`"
        >
          <textarea
            id="relationship-context"
            v-model="contextNote"
            name="relationship-context"
            maxlength="300"
            autocomplete="off"
            placeholder="Conte brevemente o contexto dessa relação…"
          />
        </DesignSystemFormField>

        <p v-if="error" class="relationship-form__error" role="alert">
          {{ error }}
        </p>
      </form>
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
      <UButton :loading="submitting" :disabled="submitting" @click="submit">
        Enviar solicitação
      </UButton>
    </template>
  </UModal>
</template>

<style scoped lang="scss">
.relationship-form {
  display: grid;
  gap: 20px;

  &__error {
    margin: 0;
    color: var(--color-danger);
    font-size: 0.88rem;
    font-weight: 700;
  }
}
</style>
