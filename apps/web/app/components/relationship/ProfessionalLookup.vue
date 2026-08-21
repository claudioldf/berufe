<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalRelationshipCandidate } from "~/services/api/professional-relationships";

const query = defineModel<string>("query", { required: true });
const selectedId = defineModel<string | null>("selectedId", { required: true });
const props = defineProps<{
  candidates: readonly ProfessionalRelationshipCandidate[];
  searching: boolean;
  searchSettled: boolean;
  searchError: string;
}>();

const selectedCandidate = computed(() =>
  props.candidates.find((candidate) => candidate.id === selectedId.value),
);
</script>

<template>
  <div class="professional-lookup">
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
        minlength="2"
        maxlength="70"
        required
      />
    </DesignSystemFormField>

    <p
      v-if="searching"
      class="professional-lookup__feedback"
      aria-live="polite"
    >
      Buscando profissionais…
    </p>
    <p
      v-else-if="searchError"
      class="professional-lookup__warning"
      role="status"
    >
      {{ searchError }} Você ainda pode continuar e informar o telefone.
    </p>

    <div v-if="selectedCandidate" class="professional-lookup__selection">
      <DesignSystemAvatar
        :name="selectedCandidate.displayName"
        :src="selectedCandidate.photoUrl ?? undefined"
        size="sm"
        shape="rounded"
      />
      <span>
        <small>Profissional selecionado</small>
        <strong>{{ selectedCandidate.displayName }}</strong>
      </span>
      <button type="button" @click="selectedId = null">Trocar</button>
    </div>
    <div
      v-else-if="candidates.length"
      class="professional-lookup__results"
      aria-label="Profissionais encontrados"
    >
      <button
        v-for="candidate in candidates"
        :key="candidate.id"
        type="button"
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
        <UIcon name="i-lucide-circle" aria-hidden="true" />
      </button>
      <p class="professional-lookup__guidance">
        Se não for nenhum deles, continue sem selecionar para informar o
        telefone.
      </p>
    </div>
    <p
      v-else-if="searchSettled && query.trim().length >= 3"
      class="professional-lookup__feedback"
    >
      Nenhum perfil encontrado. Continue para informar o telefone.
    </p>
    <p
      v-else-if="searchSettled && query.trim().length === 2"
      class="professional-lookup__feedback"
    >
      Continue digitando o nome completo.
    </p>
  </div>
</template>

<style scoped lang="scss">
.professional-lookup {
  display: grid;
  gap: 12px;

  &__feedback,
  &__warning,
  &__guidance {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.84rem;
    line-height: 1.45;
  }

  &__warning {
    color: var(--color-warning-strong);
  }

  &__guidance {
    text-align: center;
  }

  &__results {
    display: grid;
    gap: 8px;
  }

  &__results > button,
  &__selection {
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
  }

  &__results > button {
    cursor: pointer;
  }

  &__selection {
    border-color: var(--color-brand);
    background: var(--mint);
  }

  &__selection > button {
    border: 0;
    background: transparent;
    color: var(--color-brand-strong);
    font-size: 0.78rem;
    font-weight: 800;
    cursor: pointer;
  }

  &__selection strong,
  &__selection small,
  &__results strong,
  &__results small {
    display: block;
  }

  &__selection small,
  &__results small {
    margin-bottom: 2px;
    color: var(--ink-soft);
    font-size: 0.76rem;
  }
}
</style>
