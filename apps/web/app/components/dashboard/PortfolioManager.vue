<script setup lang="ts">
import { shallowRef } from "vue";
import type { PortfolioItem, PortfolioItemDraft } from "~/types";

withDefaults(
  defineProps<{ items: PortfolioItem[]; serviceOptions?: string[] }>(),
  {
    serviceOptions: () => ["Eletricista", "Marido de aluguel"],
  },
);
const emit = defineEmits<{ added: [draft: PortfolioItemDraft] }>();
const uploadOpen = shallowRef(false);

function submitUpload(draft: PortfolioItemDraft) {
  emit("added", draft);
  uploadOpen.value = false;
}
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
        <img
          :src="item.image"
          :alt="item.title"
          width="640"
          height="380"
          loading="lazy"
        />
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
        <DashboardPortfolioUploadForm
          :service-options="serviceOptions"
          show-cancel
          @cancel="uploadOpen = false"
          @submitted="submitUpload"
        />
      </template>
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
    font-family: var(--font-display);
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
    background: rgb(255 255 255 / 92%);
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
    color: var(--color-brand);
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
@media (width <= 780px) {
  .portfolio-manager {
    &__grid {
      grid-template-columns: repeat(2, 1fr);
    }
    &__intro {
      display: grid;
    }
  }
}
@media (width <= 500px) {
  .portfolio-manager {
    &__grid {
      grid-template-columns: 1fr;
    }
  }
}
</style>
