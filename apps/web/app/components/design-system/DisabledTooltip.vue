<script setup lang="ts">
import { shallowRef } from "vue";

interface Props {
  reason?: string | null;
}

const props = withDefaults(defineProps<Props>(), {
  reason: null,
});

defineSlots<{
  default(): unknown;
}>();

const open = shallowRef(false);

const tooltipPosition = {
  side: "top",
  align: "center",
  sideOffset: 10,
  collisionPadding: 12,
} as const;

const tooltipUi = {
  content:
    "h-auto max-w-[min(20rem,calc(100vw-2rem))] border-0 bg-transparent p-0 shadow-none ring-0",
  arrow: "fill-[var(--color-brand-strong)] stroke-[var(--color-brand-strong)]",
} as const;

const compatibilityClickWindow = 700;
let lastTapAt = Number.NEGATIVE_INFINITY;

// A native `disabled` control never fires hover reliably across browsers,
// is unfocusable (no keyboard route to the tooltip), and has no touch
// equivalent at all. This span is the actual trigger — always focusable and
// tappable — regardless of the disabled state of whatever it wraps.
function toggleTooltip() {
  if (!props.reason) return;
  open.value = !open.value;
}

function onTriggerClick() {
  // Touch browsers dispatch a compatibility click after pointerup. Consume
  // that click so a tap does not immediately open and close the tooltip.
  if (Date.now() - lastTapAt <= compatibilityClickWindow) {
    lastTapAt = Number.NEGATIVE_INFINITY;
    return;
  }

  toggleTooltip();
}

function onTriggerPointerUp(event: PointerEvent) {
  if (event.pointerType !== "touch" && event.pointerType !== "pen") return;
  if (!props.reason) return;

  lastTapAt = Date.now();
  toggleTooltip();
}
</script>

<template>
  <UTooltip
    v-model:open="open"
    :text="reason ?? undefined"
    :disabled="!reason"
    :content="tooltipPosition"
    :ui="tooltipUi"
    :delay-duration="250"
    arrow
    disable-closing-trigger
  >
    <span
      class="disabled-tooltip"
      :class="{ 'disabled-tooltip--boxed': reason }"
      :tabindex="reason ? 0 : -1"
      :aria-disabled="Boolean(reason)"
      @pointerup="onTriggerPointerUp"
      @click="onTriggerClick"
    >
      <slot />
    </span>

    <template v-if="reason" #content>
      <span class="disabled-tooltip__content">
        <span class="disabled-tooltip__icon" aria-hidden="true">
          <UIcon name="i-lucide-lock-keyhole" />
        </span>
        <span class="disabled-tooltip__copy">
          <strong>Ação indisponível</strong>
          <span>{{ reason }}</span>
        </span>
      </span>
    </template>
  </UTooltip>
</template>

<style scoped lang="scss">
.disabled-tooltip {
  // Stay invisible to layout so the wrapped control keeps behaving as a
  // direct flex/grid child of its real parent — this wraps existing button
  // groups without touching their surrounding layout rules.
  display: contents;

  // `display: contents` generates no box at all, so it can never itself be a
  // hover/pointer target — and a disabled control underneath is excluded
  // from hit-testing entirely, so with both invisible, a hover here would
  // dispatch nothing. Give the wrapper a real (content-sized) box only while
  // there is a reason to show, i.e. exactly when the wrapped control can't
  // receive events itself; the enabled case never needs this and keeps the
  // zero-footprint layout above.
  &--boxed {
    display: inline-flex;
  }

  &__content {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    align-items: start;
    gap: 10px;
    width: max-content;
    max-width: min(20rem, calc(100vw - 2rem));
    padding: 12px 14px;
    border: 1px solid rgb(255 255 255 / 13%);
    border-radius: var(--radius-md);
    background: linear-gradient(145deg, #214a41, var(--color-brand-strong));
    color: var(--color-text-inverse);
    text-align: left;
    box-shadow:
      0 16px 38px rgb(14 33 30 / 24%),
      0 3px 10px rgb(14 33 30 / 14%);
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 30px;
    height: 30px;
    border: 1px solid rgb(255 255 255 / 10%);
    border-radius: 9px;
    background: rgb(248 117 93 / 18%);
    color: #ffb6a8;
    font-size: 0.95rem;
  }

  &__copy,
  &__copy strong,
  &__copy > span {
    display: block;
  }

  &__copy strong {
    color: var(--color-text-inverse);
    font-size: var(--font-size-min);
    font-weight: 850;
    letter-spacing: 0.045em;
    line-height: 1.25;
    text-transform: uppercase;
  }

  &__copy > span {
    margin-top: 3px;
    color: rgb(255 255 255 / 76%);
    font-size: var(--font-size-min);
    line-height: 1.45;
    overflow-wrap: anywhere;
  }
}
</style>
