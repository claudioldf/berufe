<script setup lang="ts">
import { computed, shallowRef, watch } from "vue";
import { useProfessionalRelationships } from "~/composables/useProfessionalRelationships";
import { useToast } from "~/composables/useToast";
import type { Neighborhood, ProfessionalRelationship, Service } from "~/types";
import { normalizeBrazilianMobilePhone } from "~/utils/brazilian-phone";
import type { ExternalCoverageMode } from "./ExternalProfessionalForm.vue";
import type { ProfessionalRelationshipType } from "~/services/api/professional-relationships";

const open = defineModel<boolean>("open", { required: true });
const props = defineProps<{
  services: Service[];
  neighborhoods: Neighborhood[];
  eligible: boolean;
}>();
const emit = defineEmits<{
  created: [relationship: ProfessionalRelationship];
}>();

const { showToast } = useToast();
const relationships = useProfessionalRelationships();
const mode = shallowRef<"existing" | "external">("existing");
const relationshipType =
  shallowRef<ProfessionalRelationshipType>("recommendation");
const contextNote = shallowRef("");
const searchQuery = shallowRef("");
const selectedProfessionalId = shallowRef<string | null>(null);
const externalName = shallowRef("");
const externalPhone = shallowRef("");
const externalServiceIds = shallowRef<string[]>([]);
const externalCoverageMode = shallowRef<ExternalCoverageMode>("not_informed");
const externalNeighborhoodCodes = shallowRef<string[]>([]);
const externalAttested = shallowRef(false);
const validationError = shallowRef("");
const noteLength = computed(() => contextNote.value.length);
const error = computed(
  () => validationError.value || relationships.error.value,
);

watch(
  [open, mode, searchQuery],
  ([isOpen, selectedMode, query], _, onCleanup) => {
    if (!isOpen || selectedMode !== "existing" || query.trim().length < 2) {
      relationships.clearCandidates();
      return;
    }

    const timer = window.setTimeout(() => {
      void relationships.searchCandidates(query).catch(() => undefined);
    }, 250);
    onCleanup(() => window.clearTimeout(timer));
  },
);

watch(externalCoverageMode, (selectedMode) => {
  if (selectedMode !== "neighborhoods") externalNeighborhoodCodes.value = [];
});

watch(open, (isOpen) => {
  if (isOpen) {
    validationError.value = "";
    relationships.clearError();
    return;
  }
  reset();
});

function reset() {
  mode.value = "existing";
  relationshipType.value = "recommendation";
  contextNote.value = "";
  searchQuery.value = "";
  selectedProfessionalId.value = null;
  externalName.value = "";
  externalPhone.value = "";
  externalServiceIds.value = [];
  externalCoverageMode.value = "not_informed";
  externalNeighborhoodCodes.value = [];
  externalAttested.value = false;
  validationError.value = "";
  relationships.clearCandidates();
  relationships.clearError();
}

function selectMode(nextMode: "existing" | "external") {
  mode.value = nextMode;
  validationError.value = "";
  relationships.clearError();
}

async function submit() {
  if (relationships.isSubmitting.value || !props.eligible) return;

  validationError.value = "";
  relationships.clearError();
  let target;
  if (mode.value === "existing") {
    if (!selectedProfessionalId.value) {
      validationError.value = "Selecione um profissional para continuar.";
      return;
    }
    target = {
      type: "profile" as const,
      professionalProfileId: selectedProfessionalId.value,
    };
  } else {
    const normalizedPhone = normalizeBrazilianMobilePhone(externalPhone.value);
    if (externalName.value.trim().length < 3) {
      validationError.value = "Informe o nome profissional.";
      return;
    }
    if (!normalizedPhone) {
      validationError.value = "Informe um celular brasileiro válido com DDD.";
      return;
    }
    if (
      externalCoverageMode.value === "neighborhoods" &&
      externalNeighborhoodCodes.value.length === 0
    ) {
      validationError.value =
        "Selecione ao menos um bairro ou marque a área como não informada.";
      return;
    }
    if (!externalAttested.value) {
      validationError.value =
        "Confirme que pode compartilhar os dados profissionais.";
      return;
    }
    target = {
      type: "phone" as const,
      name: externalName.value.trim(),
      phone: normalizedPhone,
      serviceIds: externalServiceIds.value,
      coverage: {
        allJoinville: externalCoverageMode.value === "all_joinville",
        neighborhoodCodes: externalNeighborhoodCodes.value,
      },
      contactPublicationAttested: true as const,
    };
  }

  try {
    const relationship = await relationships.requestRelationship({
      target,
      relationshipType: relationshipType.value,
      contextNote: contextNote.value,
    });
    if (!relationship) return;

    await refreshNuxtData("professional-workspace");
    emit("created", relationship);
    open.value = false;
    showToast({
      title: "Solicitação enviada",
      description:
        "A relação será exibida quando o outro profissional confirmar.",
    });
  } catch {
    // The normalized API error remains visible in the dialog.
  }
}
</script>

<template>
  <UModal
    v-model:open="open"
    title="Adicionar relação profissional"
    description="Encontre alguém na Berufe ou adicione um contato profissional pelo telefone."
    :ui="{ content: 'sm:max-w-2xl' }"
  >
    <template #body>
      <div
        v-if="!eligible"
        class="relationship-create-dialog__eligibility"
        role="alert"
      >
        <UIcon name="i-lucide-shield-alert" aria-hidden="true" />
        <p>
          Para adicionar relações, conclua seu cadastro, confirme o telefone e
          tenha a identidade aprovada.
        </p>
      </div>
      <form v-else class="relationship-create-dialog" @submit.prevent="submit">
        <div
          class="relationship-create-dialog__modes"
          aria-label="Como adicionar o profissional"
        >
          <button
            type="button"
            :aria-pressed="mode === 'existing'"
            @click="selectMode('existing')"
          >
            Já está na Berufe
          </button>
          <button
            type="button"
            :aria-pressed="mode === 'external'"
            @click="selectMode('external')"
          >
            Adicionar pelo telefone
          </button>
        </div>

        <RelationshipExistingProfessionalForm
          v-if="mode === 'existing'"
          v-model:query="searchQuery"
          v-model:selected-id="selectedProfessionalId"
          :candidates="relationships.candidates.value"
          :searching="relationships.isSearching.value"
        />
        <RelationshipExternalProfessionalForm
          v-else
          v-model:name="externalName"
          v-model:phone="externalPhone"
          v-model:service-ids="externalServiceIds"
          v-model:coverage-mode="externalCoverageMode"
          v-model:neighborhood-codes="externalNeighborhoodCodes"
          v-model:attested="externalAttested"
          :services="services"
          :neighborhoods="neighborhoods"
        />

        <div class="relationship-create-dialog__context">
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
              <option value="recommendation">
                Recomendo este profissional
              </option>
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
        </div>

        <p v-if="error" class="relationship-create-dialog__error" role="alert">
          {{ error }}
        </p>
      </form>
    </template>
    <template #footer>
      <UButton
        color="neutral"
        variant="ghost"
        :disabled="relationships.isSubmitting.value"
        @click="open = false"
      >
        Cancelar
      </UButton>
      <UButton
        v-if="eligible"
        :loading="relationships.isSubmitting.value"
        :disabled="relationships.isSubmitting.value"
        @click="submit"
      >
        Enviar solicitação
      </UButton>
    </template>
  </UModal>
</template>

<style scoped lang="scss">
.relationship-create-dialog {
  display: grid;
  gap: 20px;

  &__modes {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 5px;
    padding: 4px;
    border-radius: 12px;
    background: var(--color-surface-canvas);
  }

  &__modes button {
    min-height: 42px;
    border: 0;
    border-radius: 9px;
    background: transparent;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 800;
    cursor: pointer;
  }

  &__modes button[aria-pressed="true"] {
    background: white;
    color: var(--color-brand-strong);
    box-shadow: var(--shadow-xs);
  }

  &__context {
    display: grid;
    grid-template-columns: minmax(190px, 0.7fr) 1.3fr;
    gap: 12px;
    padding-top: 18px;
    border-top: 1px solid var(--line);
  }

  &__error {
    margin: 0;
    color: var(--color-danger);
    font-size: 0.84rem;
    font-weight: 700;
  }

  &__eligibility {
    display: flex;
    gap: 10px;
    padding: 14px;
    border-radius: 12px;
    background: var(--color-warning-soft);
    color: var(--ink);
  }

  &__eligibility p {
    margin: 0;
    line-height: 1.5;
  }
}

@media (width <= 620px) {
  .relationship-create-dialog__modes,
  .relationship-create-dialog__context {
    grid-template-columns: 1fr;
  }
}
</style>
