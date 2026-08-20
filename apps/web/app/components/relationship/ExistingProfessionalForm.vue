<script setup lang="ts">
import type { ProfessionalRelationshipCandidate } from "~/services/api/professional-relationships";

const query = defineModel<string>("query", { required: true });
const selectedId = defineModel<string | null>("selectedId", { required: true });
defineProps<{
  candidates: readonly ProfessionalRelationshipCandidate[];
  searching: boolean;
}>();
</script>

<template>
  <div class="existing-professional-form">
    <DesignSystemFormField
      id="relationship-professional-search"
      label="Nome do profissional"
      hint="Digite pelo menos 2 caracteres"
      required
    >
      <input
        id="relationship-professional-search"
        v-model="query"
        name="professional-search"
        type="search"
        autocomplete="off"
        placeholder="Ex.: Rafael Oliveira"
      />
    </DesignSystemFormField>

    <p
      v-if="searching"
      class="existing-professional-form__feedback"
      aria-live="polite"
    >
      Buscando profissionais…
    </p>
    <div
      v-else-if="candidates.length"
      class="existing-professional-form__results"
      aria-label="Profissionais encontrados"
    >
      <button
        v-for="candidate in candidates"
        :key="candidate.id"
        type="button"
        :aria-pressed="selectedId === candidate.id"
        @click="selectedId = candidate.id"
      >
        <DesignSystemAvatar
          :name="candidate.displayName"
          :src="candidate.photoUrl ?? undefined"
          size="sm"
          shape="rounded"
        />
        <span>
          <strong>{{ candidate.displayName }}</strong>
          <small>
            {{
              candidate.profileType === "external"
                ? "Perfil por indicação"
                : "Profissional Berufe"
            }}
          </small>
        </span>
        <UIcon
          :name="
            selectedId === candidate.id
              ? 'i-lucide-circle-check'
              : 'i-lucide-circle'
          "
          aria-hidden="true"
        />
      </button>
    </div>
    <p
      v-else-if="query.trim().length >= 2"
      class="existing-professional-form__feedback"
    >
      Nenhum profissional encontrado. Você pode adicioná-lo pelo telefone.
    </p>
  </div>
</template>

<style scoped lang="scss">
.existing-professional-form {
  display: grid;
  gap: 12px;

  &__feedback {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.84rem;
  }

  &__results {
    display: grid;
    gap: 8px;
  }

  &__results button {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 10px;
    width: 100%;
    padding: 11px;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: white;
    color: var(--ink);
    text-align: left;
    cursor: pointer;
  }

  &__results button[aria-pressed="true"] {
    border-color: var(--color-brand);
    background: var(--mint);
  }

  &__results strong,
  &__results small {
    display: block;
  }

  &__results small {
    margin-top: 2px;
    color: var(--ink-soft);
    font-size: 0.76rem;
  }
}
</style>
