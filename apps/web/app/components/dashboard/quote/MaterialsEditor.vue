<script setup lang="ts">
import type { Quote, QuoteValidationErrors } from "~/types";

const props = defineProps<{ errors?: QuoteValidationErrors }>();
const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{
  add: [];
  remove: [id: string];
  dirty: [];
}>();

const unitSuggestions = [
  "unidade",
  "lata",
  "galão",
  "litro",
  "kg",
  "saco",
  "caixa",
  "rolo",
  "folha",
  "metro",
  "m²",
  "m³",
];
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card materials-editor">
    <header>
      <div>
        <span>04</span>
        <div>
          <h2>Materiais por conta do cliente</h2>
          <p>
            Liste o que o cliente precisa providenciar. Estes materiais não
            entram no preço do serviço.
          </p>
        </div>
      </div>
      <UButton
        size="sm"
        color="neutral"
        variant="outline"
        icon="i-lucide-plus"
        :disabled="quote.customerSuppliedMaterials.length >= 20"
        @click="emit('add')"
      >
        Adicionar material
      </UButton>
    </header>

    <div
      v-if="!quote.customerSuppliedMaterials.length"
      class="materials-editor__empty"
    >
      <UIcon name="i-lucide-package-open" aria-hidden="true" />
      <p>Nenhum material informado. Esta seção não aparecerá para o cliente.</p>
    </div>

    <div v-else class="material-list">
      <div class="material-row material-row--head" aria-hidden="true">
        <span>Material</span><span>Qtd.</span><span>Unidade</span><span />
      </div>
      <div
        v-for="(material, index) in quote.customerSuppliedMaterials"
        :key="material.id"
        class="material-row"
        @input="emit('dirty')"
      >
        <span class="material-row__mobile-index">Material {{ index + 1 }}</span>
        <label
          :class="{
            'material-row__field--invalid':
              props.errors?.materials[material.id]?.description,
          }"
        >
          <span class="material-row__label"
            >Descrição do material {{ index + 1 }}</span
          >
          <input
            v-model="material.description"
            :name="`material-${material.id}-description`"
            autocomplete="off"
            placeholder="Ex.: tinta acrílica branca 18 L"
            maxlength="160"
            :aria-describedby="
              props.errors?.materials[material.id]?.description
                ? `material-${material.id}-description-error`
                : undefined
            "
            :aria-invalid="
              Boolean(props.errors?.materials[material.id]?.description)
            "
          />
          <small
            v-if="props.errors?.materials[material.id]?.description"
            :id="`material-${material.id}-description-error`"
            class="material-row__error"
          >
            {{ props.errors.materials[material.id]?.description }}
          </small>
        </label>
        <label
          :class="{
            'material-row__field--invalid':
              props.errors?.materials[material.id]?.quantity,
          }"
        >
          <span class="material-row__label"
            >Quantidade do material {{ index + 1 }}</span
          >
          <input
            v-model.number="material.quantity"
            :name="`material-${material.id}-quantity`"
            type="number"
            inputmode="decimal"
            autocomplete="off"
            min="0.001"
            step="0.001"
            :aria-describedby="
              props.errors?.materials[material.id]?.quantity
                ? `material-${material.id}-quantity-error`
                : undefined
            "
            :aria-invalid="
              Boolean(props.errors?.materials[material.id]?.quantity)
            "
          />
          <small
            v-if="props.errors?.materials[material.id]?.quantity"
            :id="`material-${material.id}-quantity-error`"
            class="material-row__error"
          >
            {{ props.errors.materials[material.id]?.quantity }}
          </small>
        </label>
        <label
          :class="{
            'material-row__field--invalid':
              props.errors?.materials[material.id]?.unit,
          }"
        >
          <span class="material-row__label"
            >Unidade do material {{ index + 1 }}</span
          >
          <input
            v-model="material.unit"
            :name="`material-${material.id}-unit`"
            list="quote-material-unit-suggestions"
            autocomplete="off"
            placeholder="Ex.: lata"
            maxlength="20"
            :aria-describedby="
              props.errors?.materials[material.id]?.unit
                ? `material-${material.id}-unit-error`
                : undefined
            "
            :aria-invalid="Boolean(props.errors?.materials[material.id]?.unit)"
          />
          <small
            v-if="props.errors?.materials[material.id]?.unit"
            :id="`material-${material.id}-unit-error`"
            class="material-row__error"
          >
            {{ props.errors.materials[material.id]?.unit }}
          </small>
        </label>
        <button
          type="button"
          class="material-row__remove"
          :aria-label="`Remover material ${index + 1}`"
          @click="emit('remove', material.id)"
        >
          <UIcon name="i-lucide-trash-2" aria-hidden="true" />
        </button>
      </div>
      <datalist id="quote-material-unit-suggestions">
        <option v-for="unit in unitSuggestions" :key="unit" :value="unit" />
      </datalist>
    </div>

    <UButton
      class="materials-editor__mobile-add"
      color="neutral"
      variant="outline"
      block
      icon="i-lucide-plus"
      :disabled="quote.customerSuppliedMaterials.length >= 20"
      @click="emit('add')"
    >
      Adicionar material
    </UButton>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.materials-editor {
  &__empty {
    display: flex;
    gap: 10px;
    align-items: center;
    padding: 14px;
    border: 1px dashed var(--line);
    border-radius: 11px;
    color: var(--ink-soft);
  }

  &__empty svg {
    flex: 0 0 auto;
    color: var(--color-brand);
    font-size: 1.2rem;
  }

  &__empty p {
    margin: 0;
  }

  &__mobile-add {
    display: none;
    margin-top: 12px;
  }
}

.material-list {
  overflow-x: auto;
}

.material-row {
  display: grid;
  grid-template-columns: minmax(220px, 1fr) 90px 130px 32px;
  gap: 8px;
  align-items: start;
  min-width: 560px;
  padding: 8px 0;
  border-top: 1px solid var(--line);

  &--head {
    border: 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 850;
    text-transform: uppercase;
  }

  &--head span:nth-child(n + 2) {
    text-align: right;
  }

  label {
    display: grid;
    gap: 4px;
  }

  input {
    width: 100%;
    padding: 8px;
    border: 1px solid var(--line);
    border-radius: 8px;
    background-color: var(--color-surface-control);
    font-size: 0.84rem;
    transition: border-color var(--motion-fast) ease;
  }

  &__mobile-index,
  &__label {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    overflow: hidden;
    clip-path: inset(50%);
    white-space: nowrap;
    border: 0;
  }

  &__field--invalid input {
    border-color: var(--color-danger);
    background-color: var(--color-danger-tint);
  }

  &__error {
    color: var(--color-danger);
    font-size: 0.72rem;
    font-weight: 650;
    line-height: 1.25;
  }

  &__remove {
    display: grid;
    place-items: center;
    width: 27px;
    height: 27px;
    margin-top: 5px;
    border: 0;
    border-radius: 7px;
    background: transparent;
    color: #a45245;
    cursor: pointer;
  }
}

@media (width <= 720px) {
  .materials-editor {
    &__mobile-add {
      display: flex;
    }

    header > :last-child {
      display: none;
    }
  }

  .material-list {
    display: grid;
    gap: 12px;
    overflow-x: visible;
  }

  .material-row {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 12px;
    min-width: 0;
    padding: 14px;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: var(--color-surface);

    &--head {
      display: none;
    }

    &__mobile-index,
    &__label {
      position: static;
      width: auto;
      height: auto;
      overflow: visible;
      clip-path: none;
      white-space: normal;
    }

    &__mobile-index {
      align-self: center;
      color: var(--ink);
      font-size: 0.82rem;
      font-weight: 850;
    }

    &__label {
      color: var(--ink-soft);
      font-size: 0.76rem;
    }

    &__remove {
      grid-column: 2;
      grid-row: 1;
      justify-self: end;
      margin: 0;
    }

    label:first-of-type {
      grid-column: 1 / -1;
    }

    input {
      font-size: 1rem;
    }
  }
}
</style>
