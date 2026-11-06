<script setup lang="ts">
import { computed, reactive, ref, toRef, watch } from "vue";
import { useBrazilianMobilePhoneMask } from "~/composables/useBrazilianMobilePhoneMask";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  createSupportMessage,
  type SupportMessageInput,
  type SupportTopic,
} from "~/services/api/support-messages";

const props = withDefaults(
  defineProps<{
    topic?: SupportTopic;
    submit?: (input: SupportMessageInput) => Promise<void>;
  }>(),
  { topic: "geral", submit: undefined },
);

const open = defineModel<boolean>("open", { required: true });
const client = useApiClient();
const sendMessage =
  props.submit ??
  ((input: SupportMessageInput) => createSupportMessage(client, input));

const messageLimit = 2000;
const draft = reactive({ name: "", email: "", phone: "", message: "" });
const maskedPhone = useBrazilianMobilePhoneMask(toRef(draft, "phone"));
const submitting = ref(false);
const sent = ref(false);
const error = ref("");
const fieldErrors = ref<Record<string, string[]>>({});

const canSubmit = computed(
  () =>
    !submitting.value &&
    draft.name.trim().length >= 2 &&
    draft.email.trim().length > 0 &&
    draft.message.trim().length >= 10,
);

watch(open, (isOpen) => {
  if (isOpen) return;
  sent.value = false;
  error.value = "";
  fieldErrors.value = {};
});

function firstError(field: string) {
  return fieldErrors.value[field]?.[0];
}

async function submitMessage() {
  if (!canSubmit.value) return;
  submitting.value = true;
  error.value = "";
  fieldErrors.value = {};
  try {
    await sendMessage({ ...draft, topic: props.topic });
    sent.value = true;
    Object.assign(draft, { name: "", email: "", phone: "", message: "" });
  } catch (caught) {
    if (caught instanceof ApiRequestError) {
      fieldErrors.value = caught.fieldErrors ?? {};
      error.value =
        caught.code === "validation_failed"
          ? "Revise os campos destacados."
          : caught.message;
    } else {
      error.value =
        "Não foi possível enviar agora. Escreva para suporte@berufe.com.br.";
    }
  } finally {
    submitting.value = false;
  }
}
</script>

<template>
  <UModal
    v-model:open="open"
    title="Falar com o suporte"
    description="Conte o que está acontecendo e responderemos por e-mail."
  >
    <template #body>
      <div v-if="sent" class="support-modal__sent" role="status">
        <UIcon name="i-lucide-circle-check" aria-hidden="true" />
        <p><strong>Mensagem enviada.</strong></p>
        <p>Vamos responder para o e-mail que você informou.</p>
      </div>
      <form
        v-else
        id="support-contact-form"
        class="support-modal__form"
        novalidate
        @submit.prevent="submitMessage"
      >
        <DesignSystemFormField
          label="Nome"
          required
          :error="firstError('name')"
        >
          <template #default="{ controlId, describedBy, invalid, required }">
            <input
              :id="controlId"
              v-model="draft.name"
              name="name"
              type="text"
              maxlength="120"
              autocomplete="name"
              :aria-describedby="describedBy"
              :aria-invalid="invalid"
              :required="required"
            />
          </template>
        </DesignSystemFormField>
        <DesignSystemFormField
          label="E-mail"
          required
          :error="firstError('email')"
        >
          <template #default="{ controlId, describedBy, invalid, required }">
            <input
              :id="controlId"
              v-model="draft.email"
              name="email"
              type="email"
              maxlength="254"
              autocomplete="email"
              :aria-describedby="describedBy"
              :aria-invalid="invalid"
              :required="required"
            />
          </template>
        </DesignSystemFormField>
        <DesignSystemFormField
          label="Celular (opcional)"
          :error="firstError('phone')"
        >
          <template #default="{ controlId, describedBy, invalid }">
            <input
              :id="controlId"
              v-model="maskedPhone"
              name="phone"
              type="tel"
              inputmode="tel"
              autocomplete="tel"
              placeholder="(47) 9 9999-9999"
              maxlength="16"
              :aria-describedby="describedBy"
              :aria-invalid="invalid"
            />
          </template>
        </DesignSystemFormField>
        <DesignSystemFormField
          label="Mensagem"
          required
          :hint="`${draft.message.length}/${messageLimit}`"
          :error="firstError('message')"
        >
          <template #default="{ controlId, describedBy, invalid, required }">
            <textarea
              :id="controlId"
              v-model="draft.message"
              name="message"
              rows="5"
              :maxlength="messageLimit"
              :aria-describedby="describedBy"
              :aria-invalid="invalid"
              :required="required"
            />
          </template>
        </DesignSystemFormField>
        <p v-if="error" class="support-modal__error" role="alert">
          {{ error }}
        </p>
      </form>
    </template>
    <template #footer>
      <UButton color="neutral" variant="ghost" @click="open = false">
        {{ sent ? "Fechar" : "Cancelar" }}
      </UButton>
      <UButton
        v-if="!sent"
        type="submit"
        form="support-contact-form"
        color="primary"
        :loading="submitting"
        :disabled="!canSubmit"
      >
        Enviar mensagem
      </UButton>
    </template>
  </UModal>
</template>

<style scoped lang="scss">
.support-modal {
  &__form {
    display: grid;
    gap: 16px;
  }

  &__error {
    margin: 0;
    color: var(--color-danger);
    font-size: 0.86rem;
  }

  &__sent {
    display: grid;
    justify-items: center;
    gap: 6px;
    padding: 12px 0;
    text-align: center;

    & p {
      margin: 0;
    }

    & :deep(svg) {
      color: var(--color-success);
      font-size: 2.2rem;
    }
  }
}
</style>
