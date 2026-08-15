<script setup lang="ts">
const stateCode = defineModel<string>("stateCode", { default: "" });
const city = defineModel<string>("city", { default: "" });
const neighborhood = defineModel<string>("neighborhood", { default: "" });

function clearFilters() {
  stateCode.value = "";
  city.value = "";
  neighborhood.value = "";
}
</script>

<template>
  <section class="neighborhood-filters" aria-label="Filtros de bairros">
    <div class="neighborhood-filters__heading">
      <div>
        <strong>Filtrar localidades</strong>
        <small
          >A busca aceita partes do texto e ignora maiúsculas e acentos.</small
        >
      </div>
      <button type="button" @click="clearFilters">
        <UIcon name="i-lucide-rotate-ccw" /> Limpar
      </button>
    </div>
    <div class="neighborhood-filters__fields">
      <label>
        <span>UF</span>
        <input
          v-model="stateCode"
          name="filter-state-code"
          type="search"
          autocomplete="off"
          maxlength="2"
          placeholder="Ex.: SC…"
        />
      </label>
      <label>
        <span>Cidade</span>
        <input
          v-model="city"
          name="filter-city"
          type="search"
          autocomplete="off"
          maxlength="80"
          placeholder="Ex.: Joinville…"
        />
      </label>
      <label>
        <span>Bairro</span>
        <input
          v-model="neighborhood"
          name="filter-neighborhood"
          type="search"
          autocomplete="off"
          maxlength="80"
          placeholder="Ex.: América…"
        />
      </label>
    </div>
  </section>
</template>

<style scoped lang="scss">
.neighborhood-filters {
  display: grid;
  gap: 12px;
  margin: 18px 22px;
  padding: 15px;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--color-surface-hover);
  &__heading {
    display: flex;
    align-items: start;
    justify-content: space-between;
    gap: 12px;
  }
  &__heading strong,
  &__heading small {
    display: block;
  }
  &__heading strong {
    font-size: 0.86rem;
  }
  &__heading small {
    margin-top: 2px;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
  }
  &__heading button {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 5px;
    border: 0;
    background: transparent;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    font-weight: 800;
    cursor: pointer;
  }
  &__fields {
    display: grid;
    grid-template-columns: 100px minmax(180px, 0.8fr) minmax(220px, 1.2fr);
    gap: 10px;
  }
  &__fields label {
    display: grid;
    gap: 5px;
  }
  &__fields span {
    font-size: var(--font-size-min);
    font-weight: 850;
  }
  &__fields input {
    width: 100%;
    padding: 9px 10px;
    border: 1px solid var(--line-strong);
    border-radius: 9px;
    background: white;
    color: var(--ink);
    font: inherit;
    font-size: 0.84rem;
  }
}
@media (width <= 700px) {
  .neighborhood-filters {
    margin-inline: 14px;
    &__fields {
      grid-template-columns: 1fr;
    }
  }
}
</style>
