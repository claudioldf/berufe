import { readonly } from "vue";
import type { ToastMessage } from "~/types";

let toastTimer: number | undefined;

export function useToast() {
  const toast = useState<ToastMessage | null>("app-toast", () => null);

  function clearToast() {
    if (import.meta.client) window.clearTimeout(toastTimer);
    toastTimer = undefined;
    toast.value = null;
  }

  function showToast(message: ToastMessage) {
    if (import.meta.client) window.clearTimeout(toastTimer);
    toast.value = message;
    if (import.meta.client) {
      toastTimer = window.setTimeout(clearToast, 3400);
    }
  }

  return {
    toast: readonly(toast),
    clearToast,
    showToast,
  };
}
