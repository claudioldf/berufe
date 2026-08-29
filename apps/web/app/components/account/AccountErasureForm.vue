<script setup lang="ts">
import { computed, shallowRef } from "vue";

const props = defineProps<{
  recentlyVerified: boolean;
  submitting: boolean;
  error: string;
}>();

const emit = defineEmits<{
  reauthenticate: [];
  submit: [confirmation: string];
}>();

const understood = shallowRef(false);
const confirmation = shallowRef("");
const canSubmit = computed(
  () =>
    props.recentlyVerified &&
    understood.value &&
    confirmation.value === "EXCLUIR" &&
    !props.submitting,
);

function submit() {
  if (!canSubmit.value) return;
  emit("submit", confirmation.value);
}
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="erasure-form">
    <div class="erasure-form__heading">
      <span><UIcon name="i-lucide-shield-alert" aria-hidden="true" /></span>
      <div>
        <DesignSystemEyebrow>Zona de risco</DesignSystemEyebrow>
        <h2>Excluir minha conta</h2>
        <p>
          Esta ação é irreversível. Antes de confirmar, entenda o que acontece
          agora e quais registros mínimos precisam permanecer.
        </p>
      </div>
    </div>

    <ul class="erasure-form__consequences">
      <li>
        <UIcon name="i-lucide-eye-off" aria-hidden="true" />
        <span
          ><strong>Imediatamente:</strong> perfil, foto, portfólio e
          recomendações deixam de aparecer.</span
        >
      </li>
      <li>
        <UIcon name="i-lucide-link-2-off" aria-hidden="true" />
        <span
          >Todas as sessões, links de orçamento e convites de recomendação são
          revogados.</span
        >
      </li>
      <li>
        <UIcon name="i-lucide-trash-2" aria-hidden="true" />
        <span
          >Dados elegíveis do banco e do armazenamento são excluídos em até 30
          dias.</span
        >
      </li>
      <li>
        <UIcon name="i-lucide-file-lock-2" aria-hidden="true" />
        <span
          >Somente registros mínimos pseudonimizados de aceite, consentimento,
          auditoria, fraude e defesa permanecem por cinco anos. Backups seguem o
          ciclo contratado do provedor.</span
        >
      </li>
    </ul>

    <div
      class="erasure-form__verification"
      :class="{
        'erasure-form__verification--ready': recentlyVerified,
      }"
    >
      <UIcon
        :name="
          recentlyVerified ? 'i-lucide-shield-check' : 'i-lucide-smartphone'
        "
        aria-hidden="true"
      />
      <div>
        <strong>
          {{
            recentlyVerified
              ? "Telefone confirmado recentemente"
              : "Confirmação recente por SMS necessária"
          }}
        </strong>
        <p v-if="recentlyVerified">
          A confirmação vale por 30 minutos para esta ação destrutiva.
        </p>
        <p v-else>
          Confirme novamente o celular vinculado à conta antes de continuar.
        </p>
      </div>
      <UButton
        v-if="!recentlyVerified"
        type="button"
        color="primary"
        icon="i-lucide-smartphone"
        @click="emit('reauthenticate')"
      >
        Confirmar por SMS
      </UButton>
    </div>

    <form
      v-if="recentlyVerified"
      class="erasure-form__confirmation"
      @submit.prevent="submit"
    >
      <label class="erasure-form__acknowledgement">
        <input v-model="understood" type="checkbox" />
        <span
          >Entendo que a conta não poderá ser recuperada e que os dados
          elegíveis serão excluídos.</span
        >
      </label>

      <DesignSystemFormField
        id="account-erasure-confirmation"
        v-slot="field"
        label="Digite EXCLUIR para confirmar"
        hint="Use letras maiúsculas, exatamente como mostrado."
        required
      >
        <input
          :id="field.controlId"
          v-model="confirmation"
          class="erasure-form__input"
          name="confirmation"
          type="text"
          autocomplete="off"
          autocapitalize="characters"
          spellcheck="false"
          :aria-describedby="field.describedBy"
          required
        />
      </DesignSystemFormField>

      <p v-if="error" class="erasure-form__error" role="alert">
        <UIcon name="i-lucide-circle-alert" aria-hidden="true" /> {{ error }}
      </p>

      <div class="erasure-form__actions">
        <UButton to="/app/professional" color="neutral" variant="ghost">
          Cancelar
        </UButton>
        <UButton
          type="submit"
          color="error"
          icon="i-lucide-trash-2"
          :loading="submitting"
          :disabled="!canSubmit"
        >
          Excluir conta irreversivelmente
        </UButton>
      </div>
    </form>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.erasure-form {
  display: grid;
  gap: 28px;
  padding: clamp(24px, 4vw, 40px);
  border-color: color-mix(in srgb, var(--ui-error) 34%, var(--line));

  &__heading {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 16px;
  }

  &__heading > span {
    display: grid;
    place-items: center;
    width: 48px;
    height: 48px;
    border-radius: 14px;
    background: color-mix(in srgb, var(--ui-error) 12%, white);
    color: var(--ui-error);
    font-size: 1.35rem;
  }

  &__heading h2 {
    margin: 6px 0 8px;
    font-family: var(--font-display);
    font-size: clamp(1.8rem, 3vw, 2.5rem);
    font-weight: 550;
    letter-spacing: -0.035em;
  }

  &__heading p,
  &__verification p {
    margin: 0;
    color: var(--ink-soft);
    line-height: 1.65;
  }

  &__consequences {
    display: grid;
    gap: 14px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  &__consequences li {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 12px;
    align-items: start;
    line-height: 1.55;
  }

  &__consequences svg {
    margin-top: 3px;
    color: var(--ui-error);
  }

  &__verification {
    display: grid;
    grid-template-columns: auto 1fr auto;
    gap: 14px;
    align-items: center;
    padding: 18px;
    border: 1px solid var(--line);
    border-radius: var(--radius-md);
    background: var(--color-surface-warm);
  }

  &__verification--ready {
    border-color: color-mix(in srgb, var(--color-brand) 35%, var(--line));
    background: var(--mint);
  }

  &__verification > svg {
    color: var(--color-brand);
    font-size: 1.3rem;
  }

  &__verification strong {
    display: block;
    margin-bottom: 3px;
  }

  &__confirmation {
    display: grid;
    gap: 20px;
    padding-top: 4px;
  }

  &__acknowledgement {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 10px;
    color: var(--ink-soft);
    line-height: 1.55;
  }

  &__acknowledgement input {
    width: 18px;
    height: 18px;
    margin-top: 3px;
    accent-color: var(--ui-error);
  }

  &__input {
    width: 100%;
    min-height: 46px;
    padding: 11px 13px;
    border: 1px solid var(--line);
    border-radius: 10px;
    background: white;
    color: var(--ink);
    font: inherit;
    font-weight: 800;
    letter-spacing: 0.08em;
  }

  &__input:focus {
    border-color: var(--ui-error);
    outline: 3px solid color-mix(in srgb, var(--ui-error) 14%, transparent);
  }

  &__error {
    display: flex;
    gap: 7px;
    align-items: center;
    margin: 0;
    color: var(--ui-error);
    font-weight: 700;
  }

  &__actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    padding-top: 4px;
  }
}

@media (width <= 680px) {
  .erasure-form {
    &__heading,
    &__verification {
      grid-template-columns: 1fr;
    }

    &__verification :deep(.u-button) {
      justify-content: center;
      width: 100%;
    }

    &__actions {
      flex-direction: column-reverse;
    }

    &__actions :deep(.u-button) {
      justify-content: center;
      width: 100%;
    }
  }
}
</style>
