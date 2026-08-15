<script setup lang="ts">
import type { ProfessionalProfileDraft } from "~/types";
import type { SocialPlatform } from "~/utils/socialProfiles";

const form = defineModel<ProfessionalProfileDraft>({ required: true });
defineProps<{ errors: Record<SocialPlatform, string> }>();
defineEmits<{
  clear: [platform: SocialPlatform];
  validate: [platform: SocialPlatform];
}>();
</script>

<template>
  <section class="editor-section">
    <header>
      <div>
        <span>02</span>
        <div>
          <h2>Redes sociais</h2>
          <p>Ajude clientes a conhecer mais do seu trabalho.</p>
        </div>
      </div>
      <em>Opcional</em>
    </header>
    <div class="editor-grid">
      <DesignSystemFormField
        id="profile-instagram"
        v-slot="field"
        label="Instagram"
        hint="Use @perfil ou cole o link do seu perfil."
        :error="errors.instagram"
      >
        <input
          :id="field.controlId"
          v-model="form.instagram"
          name="instagram"
          type="text"
          inputmode="url"
          autocomplete="url"
          maxlength="200"
          placeholder="@seuperfil"
          :aria-describedby="field.describedBy"
          :aria-invalid="field.invalid"
          @input="$emit('clear', 'instagram')"
          @blur="$emit('validate', 'instagram')"
        />
      </DesignSystemFormField>
      <DesignSystemFormField
        id="profile-youtube"
        v-slot="field"
        label="YouTube"
        hint="Use @canal ou cole o link do seu canal."
        :error="errors.youtube"
      >
        <input
          :id="field.controlId"
          v-model="form.youtube"
          name="youtube"
          type="text"
          inputmode="url"
          autocomplete="url"
          maxlength="200"
          placeholder="@seucanal"
          :aria-describedby="field.describedBy"
          :aria-invalid="field.invalid"
          @input="$emit('clear', 'youtube')"
          @blur="$emit('validate', 'youtube')"
        />
      </DesignSystemFormField>
    </div>
  </section>
</template>
