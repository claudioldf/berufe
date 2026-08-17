<template>
  <div class="workspace-layout">
    <a class="skip-link" href="#workspace-content">Pular para o conteúdo</a>
    <AppHeader />
    <main id="workspace-content" class="workspace-layout__main" tabindex="-1">
      <slot />
    </main>
  </div>
</template>

<style scoped lang="scss">
.workspace-layout {
  min-height: 100vh;
  background: var(--color-surface-canvas);

  &__main {
    min-width: 0;
  }
}
</style>
