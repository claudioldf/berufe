<script setup lang="ts">
import type { ProfessionalProfileVisibility } from "~/types";

const props = withDefaults(
  defineProps<{
    visibility: ProfessionalProfileVisibility;
    saving?: boolean;
    disabledReason?: string | null;
    error?: string;
    publicProfilePath: string;
  }>(),
  {
    saving: false,
    disabledReason: null,
    error: "",
  },
);
const emit = defineEmits<{
  save: [visibility: ProfessionalProfileVisibility];
}>();
const selection = shallowRef<ProfessionalProfileVisibility>(props.visibility);
const options: Array<{
  value: ProfessionalProfileVisibility;
  title: string;
  description: string;
  icon: string;
}> = [
  {
    value: "discoverable",
    title: "Público e encontrável",
    description:
      "Seu perfil aparece nas buscas, páginas públicas da Berufe e mecanismos de pesquisa.",
    icon: "i-lucide-search",
  },
  {
    value: "direct_link",
    title: "Somente com o link",
    description:
      "Seu perfil não aparece em buscas ou páginas públicas, mas continua acessível para quem tiver o link.",
    icon: "i-lucide-link",
  },
  {
    value: "unpublished",
    title: "Perfil despublicado",
    description:
      "Seu perfil fica oculto em todos os lugares, inclusive no próprio link público.",
    icon: "i-lucide-eye-off",
  },
];
const changed = computed(() => selection.value !== props.visibility);
const controlsDisabled = computed(
  () => props.saving || Boolean(props.disabledReason),
);

watch(
  () => props.visibility,
  (visibility) => {
    selection.value = visibility;
  },
);

function save() {
  if (!changed.value || controlsDisabled.value) return;
  emit("save", selection.value);
}
</script>

<template>
  <section
    class="profile-visibility"
    aria-labelledby="profile-visibility-title"
  >
    <header class="profile-visibility__header">
      <div>
        <span aria-hidden="true"><UIcon name="i-lucide-shield-check" /></span>
        <div>
          <h2 id="profile-visibility-title">Visibilidade do perfil</h2>
          <p>Escolha onde clientes podem encontrar seu perfil.</p>
        </div>
      </div>
    </header>

    <form @submit.prevent="save">
      <fieldset :disabled="controlsDisabled">
        <legend class="sr-only">Quem pode encontrar seu perfil</legend>
        <label
          v-for="option in options"
          :key="option.value"
          class="visibility-option"
          :class="{
            'visibility-option--selected': selection === option.value,
            'visibility-option--danger': option.value === 'unpublished',
          }"
        >
          <input
            v-model="selection"
            type="radio"
            name="profile-visibility"
            :value="option.value"
          />
          <span class="visibility-option__icon" aria-hidden="true">
            <UIcon :name="option.icon" />
          </span>
          <span class="visibility-option__copy">
            <strong>{{ option.title }}</strong>
            <small>{{ option.description }}</small>
          </span>
        </label>
      </fieldset>

      <p v-if="props.disabledReason" class="profile-visibility__notice">
        <UIcon name="i-lucide-info" />
        {{ props.disabledReason }}
      </p>
      <p v-if="props.error" class="profile-visibility__error" role="alert">
        {{ props.error }}
      </p>

      <div class="profile-visibility__footer">
        <NuxtLink
          v-if="props.visibility !== 'unpublished'"
          :to="props.publicProfilePath"
          target="_blank"
          rel="noopener"
        >
          Ver perfil público <UIcon name="i-lucide-external-link" />
        </NuxtLink>
        <DesignSystemDisabledTooltip
          :reason="props.disabledReason"
          :loading="props.saving"
        >
          <UButton
            type="submit"
            color="primary"
            :loading="props.saving"
            :disabled="controlsDisabled || !changed"
          >
            Salvar visibilidade
          </UButton>
        </DesignSystemDisabledTooltip>
      </div>
    </form>
  </section>
</template>

<style scoped lang="scss">
.profile-visibility {
  padding: 26px;
  border: 1px solid var(--line);
  border-radius: 18px;
  margin-top: 18px;
  background: white;

  &__header {
    padding-bottom: 20px;
    border-bottom: 1px solid var(--line);
    margin-bottom: 18px;

    & > div {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    & > div > span {
      display: grid;
      width: 34px;
      height: 34px;
      place-items: center;
      border-radius: 10px;
      background: var(--mint);
      color: var(--color-brand);
    }

    h2,
    p {
      margin: 0;
    }

    h2 {
      font-family: var(--font-display);
      font-size: 1.35rem;
    }

    p {
      margin-top: 3px;
      color: var(--ink-soft);
      font-size: 0.86rem;
    }
  }

  fieldset {
    display: grid;
    padding: 0;
    border: 0;
    gap: 10px;
    margin: 0;
  }

  &__notice,
  &__error {
    display: flex;
    align-items: center;
    gap: 7px;
    margin: 14px 0 0;
    font-size: 0.84rem;
  }

  &__notice {
    color: var(--ink-soft);
  }

  &__error {
    color: var(--color-danger);
    font-weight: 700;
  }

  &__footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 14px;
    padding-top: 18px;

    a {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      color: var(--color-brand);
      font-size: 0.86rem;
      font-weight: 750;
      text-decoration: none;
    }
  }
}

.visibility-option {
  display: grid;
  grid-template-columns: auto auto minmax(0, 1fr);
  align-items: center;
  gap: 12px;
  padding: 15px;
  border: 1px solid var(--line);
  border-radius: 13px;
  background: var(--color-surface-control);
  cursor: pointer;

  &:has(input:focus-visible) {
    outline: 3px solid color-mix(in srgb, var(--color-brand) 22%, transparent);
    outline-offset: 2px;
  }

  &--selected {
    border-color: var(--color-border-strong);
    background: var(--mint);
  }

  &--danger.visibility-option--selected {
    border-color: color-mix(in srgb, var(--color-danger) 45%, var(--line));
    background: var(--color-danger-tint);
  }

  input {
    width: 17px;
    height: 17px;
    margin: 0;
    accent-color: var(--color-brand);
  }

  &__icon {
    display: grid;
    width: 32px;
    height: 32px;
    place-items: center;
    border-radius: 9px;
    background: white;
    color: var(--color-brand);
  }

  &__copy {
    min-width: 0;

    strong,
    small {
      display: block;
    }

    strong {
      color: var(--ink);
      font-size: 0.9rem;
    }

    small {
      margin-top: 3px;
      color: var(--ink-soft);
      font-size: 0.82rem;
      line-height: 1.45;
    }
  }
}

fieldset:disabled .visibility-option {
  cursor: not-allowed;
  opacity: 0.68;
}

@media (width <= 560px) {
  .profile-visibility {
    padding: 20px;

    &__footer {
      align-items: stretch;
      flex-direction: column;

      :deep(button) {
        width: 100%;
        justify-content: center;
      }
    }
  }
}
</style>
