<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalRelationshipCandidate } from "~/services/api/professional-relationships";

const query = defineModel<string>("query", { required: true });
const selectedId = defineModel<string | null>("selectedId", { required: true });
const externalSelected = defineModel<boolean>("externalSelected", {
  required: true,
});
const props = withDefaults(
  defineProps<{
    candidates: readonly ProfessionalRelationshipCandidate[];
    searching: boolean;
    searchSettled: boolean;
    searchError: string;
    validationError?: string;
  }>(),
  { validationError: "" },
);

const selectedCandidate = computed(() =>
  props.candidates.find((candidate) => candidate.id === selectedId.value),
);

function selectCandidate(candidateId: string) {
  selectedId.value = candidateId;
  externalSelected.value = false;
}

function selectExternal() {
  selectedId.value = null;
  externalSelected.value = true;
}

function clearSelection() {
  selectedId.value = null;
  externalSelected.value = false;
}
</script>

<template>
  <div class="professional-lookup">
    <DesignSystemFormField
      id="relationship-professional-search"
      v-slot="field"
      label="Nome do profissional"
      :error="props.validationError"
      required
    >
      <div class="professional-lookup__input">
        <input
          :id="field.controlId"
          v-model="query"
          name="professional-search"
          type="text"
          autocomplete="off"
          placeholder="Digite o nome do profissional aqui..."
          minlength="2"
          maxlength="70"
          required
          :aria-busy="searching"
          :aria-describedby="field.describedBy"
          :aria-invalid="field.invalid"
        />
        <UIcon
          v-if="searching"
          class="professional-lookup__loader"
          name="i-lucide-loader-circle"
          aria-hidden="true"
        />
      </div>
    </DesignSystemFormField>

    <span
      v-if="searching"
      class="professional-lookup__status"
      role="status"
      aria-live="polite"
    >
      Buscando profissionais
    </span>
    <p v-if="searchError" class="professional-lookup__warning" role="status">
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
      <button type="button" @click="clearSelection">Trocar</button>
    </div>
    <div v-else-if="externalSelected" class="professional-lookup__selection">
      <span class="professional-lookup__option-icon">
        <UIcon name="i-lucide-user-round-plus" aria-hidden="true" />
      </span>
      <span>
        <small>Adicionar novo contato</small>
        <strong>Não encontrei a pessoa na lista</strong>
      </span>
      <button type="button" @click="clearSelection">Trocar</button>
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
        @click="selectCandidate(candidate.id)"
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
      <button
        class="professional-lookup__external-option"
        type="button"
        @click="selectExternal"
      >
        <span class="professional-lookup__option-icon">
          <UIcon name="i-lucide-user-round-plus" aria-hidden="true" />
        </span>
        <span>
          <strong>Não encontrei a pessoa na lista</strong>
          <small>Continuar informando o telefone</small>
        </span>
        <UIcon name="i-lucide-circle" aria-hidden="true" />
      </button>
    </div>
    <p
      v-else-if="searchSettled && query.trim().length === 2"
      class="professional-lookup__feedback"
    >
      Continue digitando o nome completo.
    </p>
    <div
      v-else-if="searchSettled && query.trim().length >= 3"
      class="professional-lookup__empty"
    >
      <span>
        <UIcon name="i-lucide-user-round-plus" aria-hidden="true" />
      </span>
      <div>
        <strong>Essa pessoa ainda não aparece na busca.</strong>
        <p>
          Continue para informar o telefone profissional e enviar a conexão.
        </p>
      </div>
    </div>
    <div
      v-else-if="query.trim().length === 0"
      class="professional-lookup__empty"
    >
      <span><UIcon name="i-lucide-handshake" aria-hidden="true" /></span>
      <div>
        <strong>Boas conexões tornam seu perfil mais forte.</strong>
        <p>
          Busque alguém com quem você já trabalhou para criar uma recomendação
          baseada em uma parceria real.
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.professional-lookup {
  display: grid;
  gap: 12px;

  &__input {
    position: relative;
  }

  &__input input {
    width: 100%;
    height: 3rem;
    padding: 12px 42px 12px 12px;
    border: 1px solid var(--line);
    border-radius: var(--radius-md);
    background: var(--color-surface);
    color: var(--ink);
    outline: none;
    transition:
      border-color var(--motion-fast) ease,
      box-shadow var(--motion-fast) ease;
  }

  &__input input:focus-visible {
    border-color: var(--color-brand);
    box-shadow: var(--focus-ring);
  }

  &__loader {
    position: absolute;
    top: 50%;
    right: 14px;
    color: var(--color-brand);
    font-size: 1.1rem;
    pointer-events: none;
    animation: professional-lookup-spin 1s linear infinite;
  }

  &__status {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    overflow: hidden;
    clip-path: inset(50%);
    white-space: nowrap;
    border: 0;
  }

  &__feedback,
  &__warning {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.84rem;
    line-height: 1.45;
  }

  &__warning {
    color: var(--color-warning-strong);
  }

  &__empty {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    align-items: center;
    gap: 12px;
    padding: 16px;
    border: 1px solid rgb(18 98 93 / 12%);
    border-radius: 14px;
    background: var(--color-brand-tint-subtle);
  }

  &__empty > span {
    display: grid;
    place-items: center;
    width: 42px;
    height: 42px;
    border-radius: 12px;
    background: white;
    color: var(--color-brand);
    font-size: 1.25rem;
  }

  &__empty strong {
    font-size: 0.86rem;
  }

  &__empty p {
    margin: 3px 0 0;
    color: var(--ink-soft);
    font-size: 0.8rem;
    line-height: 1.45;
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

  &__option-icon {
    display: grid;
    width: 2rem;
    height: 2rem;
    place-items: center;
    border-radius: 50%;
    background: var(--mint);
    color: var(--color-brand-strong);
    font-size: 1rem;
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

.professional-lookup__results > button.professional-lookup__external-option {
  border-style: dashed;
}

@keyframes professional-lookup-spin {
  from {
    transform: translateY(-50%) rotate(0);
  }

  to {
    transform: translateY(-50%) rotate(1turn);
  }
}

@media (prefers-reduced-motion: reduce) {
  .professional-lookup__loader {
    animation: none;
    transform: translateY(-50%);
  }
}
</style>
