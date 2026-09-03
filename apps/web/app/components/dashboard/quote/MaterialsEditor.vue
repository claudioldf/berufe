<script setup lang="ts">
import type { Quote, QuoteValidationErrors } from "~/types";

const props = defineProps<{
  errors?: QuoteValidationErrors;
}>();
const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{
  add: [];
  remove: [id: string];
  dirty: [];
}>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card">
    <header>
      <div>
        <span>04</span>
        <div>
          <h2>Materiais por conta do cliente</h2>
          <p>
            Liste o que o cliente precisa comprar. Sem valores — é uma lista de
            compras.
          </p>
        </div>
      </div>
      <UButton
        size="sm"
        color="neutral"
        variant="outline"
        icon="i-lucide-plus"
        @click="emit('add')"
      >
        Adicionar material
      </UButton>
    </header>
    <p v-if="!quote.materials.length" class="quote-materials__empty">
      Nenhum material adicionado. O orçamento pode ser enviado sem esta lista.
    </p>
    <div v-else class="quote-materials">
      <div class="quote-material quote-material--head" aria-hidden="true">
        <span>Descrição</span><span>Qtd.</span><span>Unidade</span><span />
      </div>
      <div
        v-for="(material, index) in quote.materials"
        :key="material.id"
        class="quote-material"
        @input="emit('dirty')"
      >
        <span class="quote-material__mobile-index"
          >Material {{ index + 1 }}</span
        >
        <button
          class="quote-material__remove"
          type="button"
          :aria-label="`Remover material ${index + 1}`"
          @click="emit('remove', material.id)"
        >
          <UIcon name="i-lucide-trash-2" aria-hidden="true" />
        </button>
        <label
          class="quote-material__description"
          :class="{
            'quote-material__field--invalid':
              props.errors?.materials[material.id]?.description,
          }"
        >
          <span class="quote-material__label"
            >Descrição do material {{ index + 1 }}</span
          >
          <input
            v-model="material.description"
            :name="`material-${material.id}-description`"
            autocomplete="off"
            :placeholder="`Material ${index + 1}…`"
            :aria-describedby="
              props.errors?.materials[material.id]?.description
                ? `material-${material.id}-description-error`
                : undefined
            "
            :aria-invalid="
              Boolean(props.errors?.materials[material.id]?.description)
            "
            maxlength="160"
          />
          <small
            v-if="props.errors?.materials[material.id]?.description"
            :id="`material-${material.id}-description-error`"
            class="quote-material__error"
          >
            {{ props.errors.materials[material.id]?.description }}
          </small>
        </label>
        <label
          :class="{
            'quote-material__field--invalid':
              props.errors?.materials[material.id]?.quantity,
          }"
        >
          <span class="quote-material__label"
            >Quantidade do material {{ index + 1 }}</span
          >
          <input
            v-model.number="material.quantity"
            :name="`material-${material.id}-quantity`"
            type="number"
            inputmode="decimal"
            autocomplete="off"
            :aria-describedby="
              props.errors?.materials[material.id]?.quantity
                ? `material-${material.id}-quantity-error`
                : undefined
            "
            :aria-invalid="
              Boolean(props.errors?.materials[material.id]?.quantity)
            "
            min="0.01"
            step="0.01"
          />
          <small
            v-if="props.errors?.materials[material.id]?.quantity"
            :id="`material-${material.id}-quantity-error`"
            class="quote-material__error"
          >
            {{ props.errors.materials[material.id]?.quantity }}
          </small>
        </label>
        <label
          :class="{
            'quote-material__field--invalid':
              props.errors?.materials[material.id]?.unit,
          }"
        >
          <span class="quote-material__label"
            >Unidade do material {{ index + 1 }}</span
          >
          <select
            v-model="material.unit"
            :name="`material-${material.id}-unit`"
            autocomplete="off"
            :aria-describedby="
              props.errors?.materials[material.id]?.unit
                ? `material-${material.id}-unit-error`
                : undefined
            "
            :aria-invalid="Boolean(props.errors?.materials[material.id]?.unit)"
          >
            <option>unidade</option>
            <option>lata</option>
            <option>galão</option>
            <option>saco</option>
            <option>caixa</option>
            <option>pacote</option>
            <option>rolo</option>
            <option>folha</option>
            <option>barra</option>
            <option>m</option>
            <option>m²</option>
            <option>kg</option>
            <option>L</option>
          </select>
          <small
            v-if="props.errors?.materials[material.id]?.unit"
            :id="`material-${material.id}-unit-error`"
            class="quote-material__error"
          >
            {{ props.errors.materials[material.id]?.unit }}
          </small>
        </label>
      </div>
    </div>
  </DesignSystemSurfaceCard>
</template>
