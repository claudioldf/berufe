<script setup lang="ts">
import moderationData from "@data/moderation.json";

useSeoMeta({
  title: "Fila de moderação",
  robots: "noindex, nofollow",
});
definePageMeta({
  middleware: (to) => {
    if (to.query.view === "catalogos") {
      return navigateTo("/app/admin/catalog", { replace: true });
    }
    if (to.query.view === "relatorios") {
      return navigateTo("/app/admin/reports", { replace: true });
    }
  },
});
</script>

<template>
  <AdminWorkspace
    title="Fila de moderação"
    description="Analise perfis, portfólios, identidades e relações profissionais na ordem de chegada."
  >
    <div class="admin-summary">
      <article
        v-for="item in moderationData.summary"
        :key="item.label"
        :class="`admin-summary--${item.tone}`"
      >
        <span><UIcon :name="item.icon" /></span>
        <div>
          <strong>{{ item.value }}</strong
          ><small>{{ item.label }}</small>
        </div>
      </article>
    </div>

    <AdminModerationQueue />
  </AdminWorkspace>
</template>

<style scoped lang="scss">
.admin-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 9px;
  margin-bottom: 18px;
  & article {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 15px;
    border: 1px solid var(--line);
    border-radius: 14px;
    background: white;
  }
  & article > span {
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    border-radius: 10px;
    background: var(--color-surface-muted);
  }
  & strong,
  & small {
    display: block;
  }
  & strong {
    font-family: var(--font-display);
    font-size: 1.3rem;
  }
  & small {
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &--warning > span {
    background: #fff2cf !important;
    color: #947019;
  }
  &--success > span {
    background: var(--mint) !important;
    color: var(--color-brand);
  }
}
@media (width <= 800px) {
  .admin-summary {
    grid-template-columns: repeat(2, 1fr);
  }
}
@media (width <= 500px) {
  .admin-summary {
    grid-template-columns: 1fr;
  }
}
</style>
