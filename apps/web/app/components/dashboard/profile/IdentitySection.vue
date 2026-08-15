<script setup lang="ts">
import type { ProfessionalProfileDraft } from "~/types";

const form = defineModel<ProfessionalProfileDraft>({ required: true });
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
        id="profile-whatsapp"
        v-slot="field"
        label="WhatsApp profissional"
        hint="O número não aparece como texto público."
        required
      >
        <div class="phone-field">
          <em aria-hidden="true">+55</em>
          <input
            :id="field.controlId"
            v-model="form.whatsapp"
            name="whatsapp"
            required
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
        label="Frase de apresentação"
        required
      >
        <template #label>
          Frase de apresentação <em>{{ form.headline.length }}/120</em>
        </template>
        <template #default="field">
          <input
            :id="field.controlId"
            v-model="form.headline"
            name="headline"
            required
            maxlength="120"
            autocomplete="off"
            :aria-describedby="field.describedBy"
          />
        </template>
      </DesignSystemFormField>
      <DesignSystemFormField
        id="profile-bio"
        class="editor-grid__full"
        label="Conte um pouco sobre seu trabalho"
        required
      >
        <template #label>
          Conte um pouco sobre seu trabalho <em>{{ form.bio.length }}/500</em>
        </template>
        <template #default="field">
          <textarea
            :id="field.controlId"
            v-model="form.bio"
            name="bio"
            required
            maxlength="500"
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
