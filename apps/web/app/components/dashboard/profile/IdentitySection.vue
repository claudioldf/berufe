<script setup lang="ts">
import { computed, shallowRef, useTemplateRef } from "vue";
import type {
  ProfessionalProfileDraft,
  ProfessionalProfilePhotoState,
} from "~/types";
import { useImagePreview } from "~/composables/useImagePreview";
import { validateOnboardingImage } from "~/composables/useProfessionalOnboarding";

const form = defineModel<ProfessionalProfileDraft>({ required: true });
const props = withDefaults(
  defineProps<{
    photo?: ProfessionalProfilePhotoState;
    photoUploading?: boolean;
    photoRemoving?: boolean;
    allowPhotoRemoval?: boolean;
    photoError?: string;
  }>(),
  {
    photo: undefined,
    photoUploading: false,
    photoRemoving: false,
    allowPhotoRemoval: false,
    photoError: "",
  },
);
const emit = defineEmits<{
  photoSelect: [file: File];
  photoRetry: [];
  photoRemove: [];
}>();
const photoInput = useTemplateRef<HTMLInputElement>("photo-input");
const selectionError = shallowRef("");
const photoRemovalOpen = shallowRef(false);
const {
  previewUrl: selectedPhotoPreview,
  setPreviewFile,
  clearPreview,
} = useImagePreview();
const photoBusy = computed(() => props.photoUploading || props.photoRemoving);
const canRetry = computed(
  () =>
    props.photo?.latestUpload?.state === "failed" &&
    props.photo.latestUpload.retryable,
);
const hasPhoto = computed(() =>
  Boolean(props.photo?.current || props.photo?.hasPublishedPhoto),
);
const visiblePhotoUrl = computed(
  () => selectedPhotoPreview.value || props.photo?.publishedImageUrl || "",
);
const photoStatus = computed(() => {
  if (props.photoUploading) return "Enviando e processando foto…";
  if (props.photoRemoving) return "Removendo foto…";
  if (selectionError.value || props.photoError)
    return selectionError.value || props.photoError;

  const latest = props.photo?.latestUpload;
  if (latest) {
    if (["authorized", "uploaded", "processing"].includes(latest.state))
      return "Foto em processamento…";
    if (latest.state === "failed")
      return latest.retryable
        ? "Não foi possível processar a foto. Tente novamente."
        : "Essa foto não pôde ser processada. Selecione outra imagem.";
  }

  const current = props.photo?.current;
  if (!current) return "JPEG ou PNG, até 10 MB.";
  if (current.status === "pending_review")
    return "Foto salva e aguardando revisão.";
  if (current.status === "approved") return "Foto revisada.";
  if (current.status === "rejected")
    return current.rejectionReason || "Foto recusada. Selecione outra imagem.";
  if (current.status === "hidden") return "Foto oculta pela moderação.";
  return "Selecione outra foto.";
});

function openPhotoPicker() {
  if (photoBusy.value) return;
  selectionError.value = "";
  photoInput.value?.click();
}

function confirmPhotoRemoval() {
  photoRemovalOpen.value = false;
  clearPreview();
  emit("photoRemove");
}

function selectPhoto(event: Event) {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0];
  input.value = "";
  if (!file) return;

  const validation = validateOnboardingImage(file);
  selectionError.value = validation.error;
  setPreviewFile(validation.valid ? file : null);
  if (validation.valid) emit("photoSelect", file);
}
</script>

<template>
  <section class="editor-section">
    <header>
      <div>
        <span>01</span>
        <div>
          <h2>Identidade profissional</h2>
          <p>Como clientes verão e entenderão seu trabalho.</p>
        </div>
      </div>
      <em>Obrigatório</em>
    </header>
    <div class="profile-photo-control">
      <div class="profile-photo-control__avatar">
        <img
          v-if="visiblePhotoUrl"
          :src="visiblePhotoUrl"
          alt="Prévia da foto profissional"
          width="72"
          height="72"
        />
        <UIcon v-else name="i-lucide-user-round" aria-hidden="true" />
      </div>
      <div>
        <strong>Foto profissional <em>Obrigatória</em></strong>
        <p
          :class="{
            'profile-photo-control__error': selectionError || props.photoError,
          }"
          aria-live="polite"
        >
          {{ photoStatus }}
        </p>
      </div>
      <input
        ref="photo-input"
        class="profile-photo-control__input"
        name="profile-photo"
        type="file"
        accept="image/jpeg,image/png"
        :disabled="photoBusy"
        @change="selectPhoto"
      />
      <div class="profile-photo-control__actions">
        <UButton
          type="button"
          color="neutral"
          variant="outline"
          :loading="props.photoUploading"
          :disabled="photoBusy"
          @click="openPhotoPicker"
        >
          {{ hasPhoto ? "Trocar foto" : "Adicionar foto" }}
        </UButton>
        <UButton
          v-if="canRetry"
          type="button"
          color="neutral"
          variant="ghost"
          :disabled="photoBusy"
          @click="emit('photoRetry')"
        >
          Tentar novamente
        </UButton>
        <UButton
          v-if="props.allowPhotoRemoval && hasPhoto"
          type="button"
          color="error"
          variant="ghost"
          icon="i-lucide-trash-2"
          :loading="props.photoRemoving"
          :disabled="photoBusy"
          @click="photoRemovalOpen = true"
        >
          Remover foto
        </UButton>
      </div>
    </div>
    <UModal
      v-model:open="photoRemovalOpen"
      title="Remover foto do perfil?"
      description="A foto deixará de aparecer no seu perfil. Se ele estiver publicado, ficará indisponível até você adicionar outra foto."
    >
      <template #footer>
        <UButton
          type="button"
          color="neutral"
          variant="ghost"
          :disabled="photoBusy"
          @click="photoRemovalOpen = false"
        >
          Manter foto
        </UButton>
        <UButton
          type="button"
          color="error"
          icon="i-lucide-trash-2"
          :loading="props.photoRemoving"
          :disabled="photoBusy"
          @click="confirmPhotoRemoval"
        >
          Remover foto
        </UButton>
      </template>
    </UModal>
    <div class="editor-grid">
      <DesignSystemFormField
        id="profile-name"
        v-slot="field"
        label="Nome de exibição"
        required
      >
        <input
          :id="field.controlId"
          v-model="form.name"
          name="name"
          required
          maxlength="70"
          autocomplete="name"
          :aria-describedby="field.describedBy"
        />
      </DesignSystemFormField>
      <DesignSystemFormField
        id="profile-birthdate"
        v-slot="field"
        label="Data de nascimento"
        hint="Dado privado, usado somente para sua conta e conferência de identidade."
        required
      >
        <input
          :id="field.controlId"
          v-model="form.birthdate"
          name="birthdate"
          required
          type="date"
          autocomplete="bday"
          :aria-describedby="field.describedBy"
        />
      </DesignSystemFormField>
      <DesignSystemFormField
        id="profile-whatsapp"
        v-slot="field"
        label="WhatsApp profissional (opcional)"
        hint="O número não aparece como texto público, mas possibilita que os clientes entrem em contato com você."
      >
        <div class="phone-field">
          <em aria-hidden="true">+55</em>
          <input
            :id="field.controlId"
            v-model="form.whatsapp"
            name="whatsapp"
            type="tel"
            inputmode="tel"
            autocomplete="tel"
            :aria-describedby="field.describedBy"
          />
        </div>
      </DesignSystemFormField>
      <DesignSystemFormField
        id="profile-headline"
        class="editor-grid__full"
        label="Frase de apresentação (opcional)"
      >
        <template #label>
          Frase de apresentação (opcional)
          <em>{{ form.headline.length }}/120</em>
        </template>
        <template #default="field">
          <input
            :id="field.controlId"
            v-model="form.headline"
            name="headline"
            maxlength="120"
            autocomplete="off"
            :aria-describedby="field.describedBy"
          />
        </template>
      </DesignSystemFormField>
      <DesignSystemFormField
        id="profile-bio"
        class="editor-grid__full"
        label="Conte um pouco sobre seu trabalho (opcional)"
      >
        <template #label>
          Conte um pouco sobre seu trabalho (opcional)
          <em>{{ form.bio.length }}/2500</em>
        </template>
        <template #default="field">
          <textarea
            :id="field.controlId"
            v-model="form.bio"
            name="bio"
            maxlength="2500"
            :aria-describedby="field.describedBy"
          />
        </template>
      </DesignSystemFormField>
      <DesignSystemFormField
        id="profile-experience"
        v-slot="field"
        label="Anos de experiência"
        hint="Será mostrado como “experiência declarada”."
      >
        <input
          :id="field.controlId"
          v-model.number="form.yearsExperience"
          name="years-experience"
          type="number"
          inputmode="numeric"
          min="0"
          max="70"
          :aria-describedby="field.describedBy"
        />
      </DesignSystemFormField>
    </div>
  </section>
</template>

<style scoped lang="scss">
.profile-photo-control {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
  margin-bottom: 18px;
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--paper-soft);

  &__avatar {
    display: grid;
    place-items: center;
    overflow: hidden;
    width: 72px;
    height: 72px;
    border-radius: 50%;
    background: white;
    color: var(--color-brand);
    font-size: 1.35rem;
  }

  &__avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  & strong {
    display: flex;
    align-items: center;
    gap: 7px;
    color: var(--ink);
    font-size: 0.86rem;
  }

  & strong em {
    color: var(--ink-soft);
    font-size: 0.7rem;
    font-style: normal;
    font-weight: 750;
    text-transform: uppercase;
  }

  & p {
    margin: 4px 0 0;
    color: var(--ink-soft);
    font-size: 0.78rem;
  }

  &__error {
    color: var(--color-danger) !important;
  }

  &__input {
    display: none;
  }

  &__actions {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    gap: 8px;
  }
}

@media (width <= 720px) {
  .profile-photo-control {
    grid-template-columns: auto minmax(0, 1fr);

    &__actions {
      grid-column: 1 / -1;
      justify-content: center;
    }
  }
}
</style>
