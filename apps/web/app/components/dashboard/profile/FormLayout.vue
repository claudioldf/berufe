<template>
  <div class="profile-form-layout">
    <slot />
  </div>
</template>

<style scoped lang="scss">
.profile-form-layout {
  display: grid;
  gap: 18px;
}

:deep() {
  .editor-section {
    padding: 26px;
    border: 1px solid var(--line);
    border-radius: 18px;
    background: white;
  }
  .editor-section header {
    display: flex;
    justify-content: space-between;
    align-items: start;
    padding-bottom: 20px;
    margin-bottom: 22px;
    border-bottom: 1px solid var(--line);
  }
  .editor-section header > div {
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .editor-section header > div > span {
    display: grid;
    place-items: center;
    width: 34px;
    height: 34px;
    border-radius: 10px;
    background: var(--mint);
    color: var(--color-brand);
    font-family: var(--font-display);
    font-size: 0.84rem;
  }
  .editor-section h2,
  .editor-section p {
    margin: 0;
  }
  .editor-section h2 {
    font-family: var(--font-display);
    font-size: 1.35rem;
  }
  .editor-section p {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.86rem;
  }
  .editor-section header > em {
    padding: 5px 7px;
    border-radius: 7px;
    background: #efeee9;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-style: normal;
    font-weight: 900;
    text-transform: uppercase;
  }
  .editor-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 18px;
    &__full {
      grid-column: 1 / -1;
    }
  }
  .phone-field {
    display: grid;
    grid-template-columns: auto 1fr;
    border: 1px solid var(--line);
    border-radius: 10px;
    background: var(--color-surface-control);
  }
  .phone-field em {
    display: grid;
    place-items: center;
    padding: 0 11px;
    border-right: 1px solid var(--line);
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-style: normal;
    line-height: 1;
  }
  .phone-field input {
    border: 0;
  }
  .service-picker {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
  }
  .service-picker button {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 8px;
    padding: 11px;
    border: 1px solid var(--line);
    border-radius: 11px;
    background: var(--color-surface-control);
    color: var(--ink);
    text-align: left;
    cursor: pointer;
  }
  .service-picker button.selected {
    border-color: #86b9a9;
    background: #ebf6f2;
  }
  .service-picker button > span {
    display: grid;
    place-items: center;
    width: 29px;
    height: 29px;
    border-radius: 8px;
    background: var(--paper-strong);
    color: var(--color-brand);
  }
  .service-picker strong {
    font-size: 0.86rem;
  }
  .service-picker button > svg {
    color: var(--color-text-subtle);
  }
  .service-picker button.selected > svg {
    color: var(--color-brand);
  }
  .primary-service {
    max-width: 320px;
    margin-top: 18px;
  }
  .all-city {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 11px;
    padding: 15px;
    border: 1px solid var(--color-border-strong);
    border-radius: 13px;
    background: #edf7f3;
    cursor: pointer;
  }
  .all-city input {
    width: 17px;
    height: 17px;
    accent-color: var(--color-brand);
  }
  .all-city strong,
  .all-city small {
    display: block;
  }
  .all-city strong {
    font-size: 0.82rem;
  }
  .all-city small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.84rem;
  }
  .all-city > svg {
    color: var(--color-brand);
    font-size: 1.3rem;
  }
  .neighborhood-picker {
    display: flex;
    flex-wrap: wrap;
    gap: 7px;
    margin-top: 16px;
  }
  .neighborhood-picker button {
    display: flex;
    align-items: center;
    gap: 5px;
    padding: 8px 10px;
    border: 1px solid var(--line);
    border-radius: 9px;
    background: white;
    color: var(--ink);
    font-size: 0.86rem;
    cursor: pointer;
  }
  .neighborhood-picker button.selected {
    border-color: var(--color-border-strong);
    background: var(--mint);
    color: #2d695a;
  }

  @media (width <= 750px) {
    .editor-grid,
    .service-picker {
      grid-template-columns: 1fr;
    }
    .editor-grid {
      &__full {
        grid-column: auto;
      }
    }
  }
}
</style>
