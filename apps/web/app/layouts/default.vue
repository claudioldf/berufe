<template>
  <div class="public-layout">
    <a class="skip-link" href="#main-content">Pular para o conteúdo</a>
    <AppHeader />
    <main id="main-content" class="public-layout__main" tabindex="-1">
      <slot />
    </main>
    <AppFooter />
  </div>
</template>

<style scoped lang="scss">
.public-layout {
  display: flex;
  min-height: 100vh;
  flex-direction: column;

  &__main {
    flex: 1;
  }
}
</style>
