<script setup lang="ts">
import { shallowRef } from "vue";
import type { PortfolioItem } from "~/types";

defineProps<{ items: PortfolioItem[] }>();
const emit = defineEmits<{ added: [] }>();
const uploadOpen = shallowRef(false);
const title = shallowRef("");
</script>

<template>
  <div class="portfolio-manager">
    <DesignSystemSurfaceCard as="section" class="portfolio-manager__intro">
      <div>
        <DesignSystemEyebrow>Seu trabalho na prática</DesignSystemEyebrow>
        <h2>Portfólio</h2>
        <p>
          Adicione até 12 trabalhos. Novos itens entram em análise antes de
          aparecer no perfil público.
        </p>
      </div>
      <UButton
        color="primary"
        icon="i-lucide-image-plus"
        @click="uploadOpen = true"
        >Adicionar trabalho</UButton
      >
    </DesignSystemSurfaceCard>
    <div class="portfolio-manager__grid">
      <article v-for="item in items" :key="item.id">
        <img :src="item.image" :alt="item.title" />
        <div>
          <span
            ><strong>{{ item.title }}</strong
            ><small>{{ item.service }}</small></span
          ><em>Aprovado</em>
        </div>
        <button type="button" :aria-label="`Gerenciar ${item.title}`">
          <UIcon name="i-lucide-ellipsis" />
        </button>
      </article>
      <button
        v-if="items.length < 12"
        class="portfolio-manager__add"
        type="button"
        @click="uploadOpen = true"
      >
        <UIcon name="i-lucide-plus" /><strong>Adicionar trabalho</strong
        ><small>{{ items.length }} de 12 publicados</small>
      </button>
    </div>
    <UModal
      v-model:open="uploadOpen"
      title="Adicionar trabalho"
      description="A imagem ficará privada até a aprovação."
    >
      <template #body>
        <form
          id="portfolio-upload"
          class="portfolio-upload"
          @submit.prevent="
            uploadOpen = false;
            emit('added');
          "
        >
          <label class="portfolio-upload__drop"
            ><UIcon name="i-lucide-cloud-upload" /><strong
              >Arraste uma foto ou selecione do dispositivo</strong
            ><small>JPG ou PNG · até 10 MB</small
            ><input type="file" accept="image/jpeg,image/png"
          /></label>
          <DesignSystemFormField label="Título do trabalho"
            ><input
              v-model="title"
              required
              maxlength="80"
              placeholder="Ex.: Iluminação da cozinha"
          /></DesignSystemFormField>
          <DesignSystemFormField label="Serviço"
            ><select required>
              <option>Eletricista</option>
              <option>Marido de aluguel</option>
            </select></DesignSystemFormField
          >
          <DesignSystemFormField label="Descrição opcional">
            <textarea
              maxlength="300"
              placeholder="Explique brevemente o que foi feito..."
            />
          </DesignSystemFormField>
        </form>
      </template>
      <template #footer
        ><UButton color="neutral" variant="ghost" @click="uploadOpen = false"
          >Cancelar</UButton
        ><UButton
          type="submit"
          form="portfolio-upload"
          color="primary"
          :disabled="!title"
          >Enviar para análise</UButton
        ></template
      >
    </UModal>
  </div>
</template>

<style scoped lang="scss">
.portfolio-manager {
  display: grid;
  gap: 18px;
  &__intro {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 30px;
    padding: 26px;
  }
  &__intro h2 {
    margin: 0;
    font-family: Georgia, serif;
    font-size: 2rem;
  }
  &__intro p:last-child {
    max-width: 580px;
    margin: 7px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
  }
  &__grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }
  &__grid article {
    position: relative;
    overflow: hidden;
    border: 1px solid var(--line);
    border-radius: 16px;
    background: white;
  }
  &__grid article > img {
    width: 100%;
    height: 190px;
    object-fit: cover;
  }
  &__grid article > div {
    display: flex;
    justify-content: space-between;
    gap: 8px;
    padding: 13px;
  }
  &__grid strong,
  &__grid small {
    display: block;
  }
  &__grid strong {
    font-size: 0.82rem;
  }
  &__grid small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &__grid em {
    align-self: start;
    padding: 4px 6px;
    border-radius: 6px;
    background: #e5f3ee;
    color: #2e6f5e;
    font-size: 0.82rem;
    font-style: normal;
    font-weight: 900;
  }
  &__grid article > button {
    position: absolute;
    top: 9px;
    right: 9px;
    display: grid;
    place-items: center;
    width: 31px;
    height: 31px;
    border: 0;
    border-radius: 9px;
    background: rgba(255, 255, 255, 0.92);
    cursor: pointer;
  }
  &__add {
    min-height: 260px;
    display: grid;
    place-items: center;
    align-content: center;
    gap: 5px;
    border: 1px dashed #9ab9af;
    border-radius: 16px;
    background: transparent;
    color: #397a69;
    cursor: pointer;
  }
  &__add > svg {
    margin-bottom: 5px;
    font-size: 1.5rem;
  }
  &__add small {
    color: var(--ink-soft);
  }
}
.portfolio-upload {
  display: grid;
  gap: 14px;
  &__drop {
    position: relative;
    display: grid;
    gap: 6px;
    color: var(--ink);
    font-size: 0.86rem;
    font-weight: 800;
    place-items: center;
    padding: 30px;
    border: 1px dashed #8eb6aa;
    border-radius: 13px;
    background: #eff7f4;
    text-align: center;
    cursor: pointer;
  }
  &__drop svg {
    color: #397a69;
    font-size: 1.8rem;
  }
  &__drop small {
    color: var(--ink-soft);
  }
  &__drop input {
    position: absolute;
    inset: 0;
    opacity: 0;
    cursor: pointer;
  }
}
@media (max-width: 780px) {
  .portfolio-manager {
    &__grid {
      grid-template-columns: repeat(2, 1fr);
    }
    &__intro {
      display: grid;
    }
  }
}
@media (max-width: 500px) {
  .portfolio-manager {
    &__grid {
      grid-template-columns: 1fr;
    }
  }
}
</style>
