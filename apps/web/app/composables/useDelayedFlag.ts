import { onScopeDispose, shallowRef, watch } from "vue";
import type { WatchSource } from "vue";

/**
 * Turns `true` only after `source` has stayed `true` for `delayMs`, and back
 * to `false` as soon as `source` does. A source that flips back before the
 * delay elapses never shows, so fast work produces no flicker.
 */
export function useDelayedFlag(source: WatchSource<boolean>, delayMs: number) {
  const delayed = shallowRef(false);
  let timer: ReturnType<typeof setTimeout> | undefined;

  function clear() {
    if (timer === undefined) return;
    clearTimeout(timer);
    timer = undefined;
  }

  watch(
    source,
    (active) => {
      clear();
      if (!active) {
        delayed.value = false;
        return;
      }
      timer = setTimeout(() => {
        timer = undefined;
        delayed.value = true;
      }, delayMs);
    },
    { immediate: true },
  );

  onScopeDispose(clear);

  return delayed;
}
