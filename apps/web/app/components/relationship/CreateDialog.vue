<script setup lang="ts">
import { computed, shallowRef, useTemplateRef, watch } from "vue";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";
import { useProfessionalRelationships } from "~/composables/useProfessionalRelationships";
import { useToast } from "~/composables/useToast";
import type {
  LocationCoverageDraft,
  ProfessionalRelationship,
  Service,
} from "~/types";
import { normalizeBrazilianMobilePhone } from "~/utils/brazilian-phone";
import type { ExternalCoverageMode } from "./ExternalProfessionalDetails.vue";
import type { ProfessionalRelationshipType } from "~/services/api/professional-relationships";

const CANDIDATE_SEARCH_DEBOUNCE_MS = 500;

const open = defineModel<boolean>("open", { required: true });
const props = defineProps<{
  services: Service[];
  eligible: boolean;
}>();
const emit = defineEmits<{
  created: [relationship: ProfessionalRelationship];
}>();
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const { validationAttempted, revealValidation, resetValidation } =
  useInlineFormValidation(formRoot);

const { showToast } = useToast();
const relationships = useProfessionalRelationships();
const step = shallowRef<"lookup" | "details">("lookup");
const relationshipType =
  shallowRef<ProfessionalRelationshipType>("recommendation");
const contextNote = shallowRef("");
const searchQuery = shallowRef("");
const selectedProfessionalId = shallowRef<string | null>(null);
const externalProfessionalSelected = shallowRef(false);
const candidateSearchPending = shallowRef(false);
const externalPhone = shallowRef("");
const externalServiceIds = shallowRef<string[]>([]);
const externalCoverageMode = shallowRef<ExternalCoverageMode>("not_informed");
const externalCoverage = shallowRef<LocationCoverageDraft>({
  cityCode: "",
  wholeCity: false,
  neighborhoodCodes: [],
});
const normalizedName = computed(() => searchQuery.value.trim());
const noteLength = computed(() => contextNote.value.length);
const searchSettled = computed(
  () =>
    normalizedName.value.length >= 2 &&
    relationships.searchedQuery.value === normalizedName.value &&
    !relationships.isSearching.value,
);
const candidateSearchLoading = computed(
  () => candidateSearchPending.value || relationships.isSearching.value,
);
const selectedCandidate = computed(() =>
  relationships.candidates.value.find(
    (candidate) => candidate.id === selectedProfessionalId.value,
  ),
);
const canContinue = computed(
  () =>
    Boolean(selectedProfessionalId.value) ||
    (normalizedName.value.length >= 3 &&
      searchSettled.value &&
      (relationships.candidates.value.length === 0 ||
        externalProfessionalSelected.value)),
);
const externalTarget = computed(
  () => step.value === "details" && !selectedProfessionalId.value,
);
const modalDescription = computed(() =>
  step.value === "lookup"
    ? "Encontre o profissional pelo nome. Se ele ainda não estiver na Berufe, você poderá informar o telefone na próxima etapa."
    : "Revise o profissional e conte como vocês se conhecem.",
);
const lookupValidationError = computed(() => {
  if (canContinue.value) return "";
  if (normalizedName.value.length < 3)
    return "Informe o nome profissional para continuar.";
  if (!searchSettled.value) return "Aguarde a busca terminar para continuar.";
  return "Selecione um profissional ou a opção para adicionar um novo contato.";
});
const phoneValidationError = computed(() =>
  normalizeBrazilianMobilePhone(externalPhone.value)
    ? ""
    : "Informe um celular brasileiro válido com DDD.",
);
const coverageValidationError = computed(() => {
  if (externalCoverageMode.value !== "informed") return "";
  return externalCoverage.value.cityCode
    ? ""
    : 'Selecione o estado e a cidade ou marque "Não sei".';
});
const displayedLookupError = computed(() =>
  validationAttempted.value ? lookupValidationError.value : "",
);
const displayedPhoneError = computed(() =>
  validationAttempted.value ? phoneValidationError.value : "",
);
const displayedCoverageError = computed(() =>
  validationAttempted.value ? coverageValidationError.value : "",
);
const externalDetailsValid = computed(
  () => !phoneValidationError.value && !coverageValidationError.value,
);
const error = computed(() => relationships.error.value);
const submittingReason = computed(() =>
  relationships.isSubmitting.value
    ? "Aguarde o envio da solicitação de conexão terminar."
    : null,
);
const candidateSearchBlockedReason = computed(() =>
  candidateSearchLoading.value
    ? "Aguarde a busca de profissionais terminar."
    : null,
);
let candidateSearchAttempt = 0;

watch([open, searchQuery], ([isOpen, query], _, onCleanup) => {
  const searchAttempt = ++candidateSearchAttempt;
  selectedProfessionalId.value = null;
  externalProfessionalSelected.value = false;
  candidateSearchPending.value = false;
  step.value = "lookup";
  relationships.clearError();
  relationships.clearCandidates();

  const normalized = query.trim();
  if (!isOpen || normalized.length === 0) return;

  candidateSearchPending.value = true;
  const timer = window.setTimeout(() => {
    if (normalized.length < 2) {
      if (searchAttempt === candidateSearchAttempt) {
        candidateSearchPending.value = false;
      }
      return;
    }

    void relationships
      .searchCandidates(normalized)
      .catch(() => undefined)
      .finally(() => {
        if (searchAttempt === candidateSearchAttempt) {
          candidateSearchPending.value = false;
        }
      });
  }, CANDIDATE_SEARCH_DEBOUNCE_MS);
  onCleanup(() => window.clearTimeout(timer));
});

watch([selectedProfessionalId, externalProfessionalSelected], () => {
  relationships.clearError();
});

watch(externalCoverageMode, (selectedMode) => {
  if (selectedMode !== "informed") {
    externalCoverage.value = {
      cityCode: "",
      wholeCity: false,
      neighborhoodCodes: [],
    };
  }
});

watch(open, (isOpen) => {
  if (!isOpen) reset();
});

function reset() {
  step.value = "lookup";
  relationshipType.value = "recommendation";
  contextNote.value = "";
  searchQuery.value = "";
  selectedProfessionalId.value = null;
  externalProfessionalSelected.value = false;
  candidateSearchPending.value = false;
  externalPhone.value = "";
  externalServiceIds.value = [];
  externalCoverageMode.value = "not_informed";
  externalCoverage.value = {
    cityCode: "",
    wholeCity: false,
    neighborhoodCodes: [],
  };
  resetValidation();
  relationships.clearCandidates();
  relationships.clearError();
}

function continueToDetails() {
  relationships.clearError();
  if (!revealValidation(canContinue.value)) return;

  step.value = "details";
  resetValidation();
}

function returnToLookup() {
  step.value = "lookup";
  resetValidation();
  relationships.clearError();
}

async function submit() {
  if (
    step.value !== "details" ||
    relationships.isSubmitting.value ||
    !props.eligible
  ) {
    return;
  }

  relationships.clearError();
  let target;
  if (selectedProfessionalId.value) {
    target = {
      type: "profile" as const,
      professionalProfileId: selectedProfessionalId.value,
    };
  } else {
    const normalizedPhone = normalizeBrazilianMobilePhone(externalPhone.value);
    if (!revealValidation(externalDetailsValid.value) || !normalizedPhone)
      return;
    target = {
      type: "phone" as const,
      name: normalizedName.value,
      phone: normalizedPhone,
      serviceIds: externalServiceIds.value,
      coverage: {
        cityCode:
          externalCoverageMode.value === "informed"
            ? externalCoverage.value.cityCode
            : null,
        wholeCity:
          externalCoverageMode.value === "informed" &&
          Boolean(externalCoverage.value.cityCode),
        neighborhoodCodes: [],
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
      title: "Solicitação de conexão enviada",
      description:
        "A conexão aparecerá nos perfis quando o outro profissional confirmar.",
    });
  } catch {
    // The normalized API error remains visible in the dialog.
  }
}
</script>

<template>
  <UModal
    v-model:open="open"
    title="Conectar com um profissional"
    :description="modalDescription"
    :ui="{ content: 'sm:max-w-2xl' }"
  >
    <template #body>
      <div
        v-if="!eligible"
        class="relationship-create-dialog__eligibility"
        role="alert"
      >
        <UIcon
          class="relationship-create-dialog__eligibility-icon"
          name="i-lucide-shield-alert"
          aria-hidden="true"
        />
        <div>
          <span>Ative sua rede profissional</span>
          <h3>Prepare seu perfil para criar conexões reais.</h3>
          <p>
            Para se conectar com outros profissionais, conclua seu cadastro,
            confirme o telefone e tenha a identidade aprovada.
          </p>
          <ul>
            <li>
              <UIcon name="i-lucide-circle-check" aria-hidden="true" />
              Recomendações confirmadas fortalecem os dois perfis
            </li>
            <li>
              <UIcon name="i-lucide-circle-check" aria-hidden="true" />
              Clientes enxergam parcerias baseadas em trabalho real
            </li>
          </ul>
          <UButton
            to="/app/professional/profile?tab=verificacoes"
            color="primary"
            icon="i-lucide-shield-check"
            @click="open = false"
          >
            Concluir meu perfil
          </UButton>
        </div>
      </div>
      <form
        v-else
        ref="formRoot"
        class="relationship-create-dialog"
        novalidate
        @submit.prevent="submit"
      >
        <RelationshipProfessionalLookup
          v-if="step === 'lookup'"
          v-model:query="searchQuery"
          v-model:selected-id="selectedProfessionalId"
          v-model:external-selected="externalProfessionalSelected"
          :candidates="relationships.candidates.value"
          :searching="candidateSearchLoading"
          :search-settled="searchSettled"
          :search-error="relationships.searchError.value"
          :validation-error="displayedLookupError"
        />

        <template v-else>
          <div class="relationship-create-dialog__target">
            <DesignSystemAvatar
              :name="selectedCandidate?.displayName ?? normalizedName"
              :src="selectedCandidate?.photoUrl ?? undefined"
              size="sm"
              shape="rounded"
            />
            <span>
              <small>
                {{
                  externalTarget
                    ? "Contato profissional"
                    : "Profissional selecionado"
                }}
              </small>
              <strong>{{
                selectedCandidate?.displayName ?? normalizedName
              }}</strong>
            </span>
          </div>

          <RelationshipExternalProfessionalDetails
            v-if="externalTarget"
            v-model:phone="externalPhone"
            v-model:coverage-mode="externalCoverageMode"
            v-model:coverage="externalCoverage"
            :phone-error="displayedPhoneError"
            :coverage-error="displayedCoverageError"
          />

          <div class="relationship-create-dialog__context">
            <DesignSystemFormField
              id="relationship-type"
              label="Como vocês se conhecem?"
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
              label="Comentário"
              hint="Opcional. Este comentário será exibido publicamente quando o profissional se cadastrar na Berufe."
            >
              <template #label>
                Comentário <em>{{ noteLength }}/300</em>
              </template>
              <template #default="field">
                <textarea
                  :id="field.controlId"
                  v-model="contextNote"
                  name="relationship-context"
                  maxlength="300"
                  autocomplete="off"
                  placeholder="Conte brevemente como vocês se conhecem…"
                  :aria-describedby="field.describedBy"
                />
              </template>
            </DesignSystemFormField>
          </div>

          <RelationshipExternalProfessionalServices
            v-if="externalTarget"
            v-model="externalServiceIds"
            :services="services"
          />
        </template>

        <p v-if="error" class="relationship-create-dialog__error" role="alert">
          {{ error }}
        </p>
      </form>
    </template>
    <template #footer>
      <DesignSystemDisabledTooltip
        v-if="step === 'lookup'"
        :reason="submittingReason"
      >
        <UButton
          color="neutral"
          variant="ghost"
          :disabled="relationships.isSubmitting.value"
          @click="open = false"
        >
          Cancelar
        </UButton>
      </DesignSystemDisabledTooltip>
      <DesignSystemDisabledTooltip v-else :reason="submittingReason">
        <UButton
          color="neutral"
          variant="ghost"
          :disabled="relationships.isSubmitting.value"
          @click="returnToLookup"
        >
          Voltar
        </UButton>
      </DesignSystemDisabledTooltip>
      <DesignSystemDisabledTooltip
        v-if="eligible && step === 'lookup'"
        :reason="candidateSearchBlockedReason"
      >
        <UButton :disabled="candidateSearchLoading" @click="continueToDetails">
          Continuar
        </UButton>
      </DesignSystemDisabledTooltip>
      <DesignSystemDisabledTooltip
        v-else-if="eligible"
        :reason="submittingReason"
      >
        <UButton
          :loading="relationships.isSubmitting.value"
          :disabled="relationships.isSubmitting.value"
          @click="submit"
        >
          Conectar
        </UButton>
      </DesignSystemDisabledTooltip>
    </template>
  </UModal>
</template>

<style scoped lang="scss">
.relationship-create-dialog {
  display: grid;
  gap: 20px;

  &__target {
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    gap: 10px;
    padding: 11px;
    border: 1px solid var(--color-brand);
    border-radius: 12px;
    background: var(--mint);
  }

  &__target strong,
  &__target small {
    display: block;
  }

  &__target small {
    margin-bottom: 2px;
    color: var(--ink-soft);
    font-size: 0.76rem;
  }

  &__context {
    display: grid;
    grid-template-columns: 1fr;
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
    align-items: flex-start;
    gap: 18px;
    padding: 24px;
    border: 1px solid rgb(18 98 93 / 14%);
    border-radius: 18px;
    background:
      radial-gradient(circle at 100% 0%, var(--mint), transparent 42%),
      var(--color-brand-tint-subtle);
    color: var(--ink);
  }

  &__eligibility-icon {
    flex: 0 0 3rem;
    width: 3rem;
    height: 3rem;
    color: var(--color-brand);
    font-size: 3rem;
  }

  &__eligibility > div > span {
    color: var(--color-brand);
    font-size: 0.74rem;
    font-weight: 850;
    letter-spacing: 0.04em;
    text-transform: uppercase;
  }

  &__eligibility h3 {
    margin: 7px 0;
    font-family: var(--font-display);
    font-size: 1.55rem;
    font-weight: 500;
    letter-spacing: -0.03em;
    line-height: 1.08;
  }

  &__eligibility p {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.88rem;
    line-height: 1.55;
  }

  &__eligibility ul {
    display: grid;
    gap: 7px;
    margin: 16px 0 18px;
    padding: 0;
    list-style: none;
  }

  &__eligibility li {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 0.8rem;
    font-weight: 720;
  }

  &__eligibility li svg {
    flex: 0 0 auto;
    color: var(--color-brand);
  }
}

@media (width <= 520px) {
  .relationship-create-dialog__eligibility {
    display: grid;
  }
}
</style>
