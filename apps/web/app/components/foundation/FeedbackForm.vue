<script setup lang="ts">
import { reactive, ref } from "vue";

export interface FoundationFeedback {
  name: string;
  note: string;
}

defineProps<{
  submitting?: boolean;
}>();

const emit = defineEmits<{
  submitted: [feedback: FoundationFeedback];
}>();

const state = reactive<FoundationFeedback>({ name: "", note: "" });
const nameError = ref("");

function submit() {
  nameError.value =
    state.name.trim().length >= 2 ? "" : "Informe seu nome completo.";
  if (nameError.value) return;

  emit("submitted", {
    name: state.name.trim(),
    note: state.note.trim(),
  });
}

function reset() {
  state.name = "";
  state.note = "";
  nameError.value = "";
}
</script>

<template>
  <form
    class="feedback-form"
    novalidate
    @submit.prevent="submit"
    @reset.prevent="reset"
  >
    <div>
      <DesignSystemEyebrow>Formulário</DesignSystemEyebrow>
      <h2>Controles e validação</h2>
      <p>
        Feedback imediato ajuda a pessoa; a API continuará sendo a autoridade.
      </p>
    </div>

    <UFormField
      label="Nome"
      name="name"
      description="Use pelo menos dois caracteres."
      :error="nameError"
      required
    >
      <UInput
        v-model="state.name"
        class="w-full"
        autocomplete="name"
        placeholder="Seu nome"
        @update:model-value="nameError = ''"
      />
    </UFormField>

    <UFormField label="Observação" name="note">
      <UTextarea
        v-model="state.note"
        class="w-full"
        :rows="4"
        placeholder="O que devemos melhorar?"
      />
    </UFormField>

    <p v-if="nameError" class="feedback-form__alert" role="alert">
      {{ nameError }}
    </p>

    <div class="feedback-form__actions">
      <UButton type="submit" icon="i-lucide-send" :loading="submitting">
        Enviar demonstração
      </UButton>
      <UButton type="reset" color="neutral" variant="outline"> Limpar </UButton>
    </div>
  </form>
</template>

<style scoped lang="scss">
.feedback-form {
  display: grid;
  gap: 22px;
  padding: clamp(24px, 5vw, 40px);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-xl);
  background: var(--color-surface);

  h2 {
    margin: 8px 0;
    font-family: var(--font-display);
    font-size: 2rem;
    font-weight: 500;
    letter-spacing: -0.03em;
  }

  p {
    margin: 0;
    color: var(--color-text-muted);
  }

  &__alert {
    color: var(--color-danger) !important;
    font-weight: 700;
  }

  &__actions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
  }
}
</style>
