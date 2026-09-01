<script setup lang="ts">
import { computed, reactive, toRef, watch } from "vue";
import type { ProfessionalCustomer, ProfessionalCustomerDraft } from "~/types";
import { useBrazilianMobilePhoneMask } from "~/composables/useBrazilianMobilePhoneMask";

const props = withDefaults(
  defineProps<{
    customer: ProfessionalCustomer;
    saving?: boolean;
    error?: string;
    fieldErrors?: Record<string, string[]>;
  }>(),
  {
    saving: false,
    error: "",
    fieldErrors: () => ({}),
  },
);

const emit = defineEmits<{
  save: [draft: ProfessionalCustomerDraft];
}>();

const draft = reactive<ProfessionalCustomerDraft>({
  name: props.customer.name,
  phone: props.customer.phone,
  email: props.customer.email,
});
const maskedPhone = useBrazilianMobilePhoneMask(toRef(draft, "phone"));
const savingReason = computed(() =>
  props.saving ? "Aguarde o salvamento dos dados do cliente terminar." : null,
);

watch(
  () => props.customer,
  (customer) => {
    draft.name = customer.name;
    draft.phone = customer.phone;
    draft.email = customer.email;
  },
);

function firstError(field: string) {
  return props.fieldErrors[field]?.[0];
}

function submit() {
  emit("save", { ...draft });
}
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="customer-contact">
    <header>
      <div>
        <DesignSystemEyebrow>Cadastro</DesignSystemEyebrow>
        <h2>Dados do cliente</h2>
      </div>
      <span v-if="customer.emailVerified" class="customer-contact__verified">
        <UIcon name="i-lucide-badge-check" aria-hidden="true" />
        E-mail verificado
      </span>
    </header>

    <form @submit.prevent="submit">
      <DesignSystemFormField
        class="customer-contact__name-field"
        label="Nome"
        required
        :error="firstError('name')"
      >
        <template #default="{ controlId, describedBy, invalid, required }">
          <input
            :id="controlId"
            v-model="draft.name"
            name="customerName"
            type="text"
            maxlength="80"
            autocomplete="name"
            :aria-describedby="describedBy"
            :aria-invalid="invalid"
            :required="required"
          />
        </template>
      </DesignSystemFormField>
      <DesignSystemFormField
        label="WhatsApp"
        required
        :error="firstError('whatsapp_e164')"
      >
        <template #default="{ controlId, describedBy, invalid, required }">
          <input
            :id="controlId"
            v-model="maskedPhone"
            name="customerPhone"
            type="tel"
            inputmode="tel"
            autocomplete="tel"
            placeholder="(47) 9 9999-9999"
            maxlength="16"
            :aria-describedby="describedBy"
            :aria-invalid="invalid"
            :required="required"
          />
        </template>
      </DesignSystemFormField>
      <DesignSystemFormField
        label="E-mail (opcional)"
        hint="Se o e-mail mudar, ele precisará ser verificado novamente."
        :error="firstError('email')"
      >
        <template #default="{ controlId, describedBy, invalid }">
          <input
            :id="controlId"
            v-model="draft.email"
            name="customerEmail"
            type="email"
            maxlength="254"
            autocomplete="email"
            :aria-describedby="describedBy"
            :aria-invalid="invalid"
          />
        </template>
      </DesignSystemFormField>

      <p v-if="error" class="customer-contact__error" role="alert">
        {{ error }}
      </p>
      <div class="customer-contact__actions">
        <DesignSystemDisabledTooltip :reason="savingReason">
          <button type="submit" :disabled="saving">
            <UIcon
              :name="saving ? 'i-lucide-loader-circle' : 'i-lucide-save'"
              aria-hidden="true"
            />
            {{ saving ? "Salvando…" : "Salvar alterações" }}
          </button>
        </DesignSystemDisabledTooltip>
      </div>
    </form>

    <aside>
      <UIcon name="i-lucide-info" aria-hidden="true" />
      <p>
        Estas alterações serão usadas em novos orçamentos. Os dados registrados
        nos orçamentos anteriores continuam como estavam quando foram criados.
      </p>
    </aside>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.customer-contact {
  padding: 24px;

  & header {
    display: flex;
    align-items: start;
    justify-content: space-between;
    gap: 18px;
    margin-bottom: 22px;
  }

  & h2 {
    margin: 5px 0 0;
    font-family: var(--font-display);
    font-size: 1.7rem;
    font-weight: 550;
  }

  &__verified {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 9px;
    border-radius: var(--radius-pill);
    background: var(--color-success-tint);
    color: var(--color-success);
    font-size: 0.76rem;
    font-weight: 850;
  }

  & form {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 18px;
  }

  &__name-field,
  &__error,
  &__actions {
    grid-column: 1 / -1;
  }

  &__error {
    margin: 0;
    color: var(--color-danger);
    font-size: 0.84rem;
  }

  &__actions {
    display: flex;
    justify-content: end;
  }

  &__actions button {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    padding: 11px 16px;
    border: 0;
    border-radius: var(--radius-pill);
    background: var(--color-brand);
    color: white;
    font-weight: 800;
    cursor: pointer;
  }

  &__actions button:disabled {
    cursor: wait;
    opacity: 0.65;
  }

  & aside {
    display: flex;
    gap: 9px;
    align-items: start;
    margin-top: 22px;
    padding: 13px 14px;
    border-radius: var(--radius-md);
    background: var(--color-brand-tint-subtle);
    color: var(--ink-soft);
  }

  & aside p {
    margin: 0;
    font-size: 0.8rem;
    line-height: 1.5;
  }
}

@media (width <= 620px) {
  .customer-contact {
    padding: 19px;

    & header {
      flex-direction: column;
    }

    & form {
      grid-template-columns: 1fr;
    }

    & form > * {
      grid-column: 1;
    }
  }
}
</style>
