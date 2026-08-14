import type { ToastMessage } from "~/types";

export function useMockupApp() {
  const toast = useState<ToastMessage | null>("mockup-toast", () => null);
  const activeRole = useState<"visitor" | "professional" | "admin">(
    "mockup-role",
    () => "visitor",
  );
  let toastTimer: ReturnType<typeof setTimeout> | undefined;

  function clearToast() {
    toast.value = null;
  }

  function showToast(message: ToastMessage) {
    toast.value = message;
    if (import.meta.client) {
      window.clearTimeout(toastTimer);
      toastTimer = window.setTimeout(clearToast, 3400);
    }
  }

  async function copyText(value: string, message = "Link copiado") {
    if (import.meta.client && navigator.clipboard) {
      await navigator.clipboard.writeText(value);
    }
    showToast({
      title: message,
      description: "Pronto para você compartilhar.",
    });
  }

  async function share(options: { title: string; text: string; url: string }) {
    if (import.meta.client && navigator.share) {
      await navigator.share(options);
      return;
    }
    await copyText(options.url);
  }

  function money(value: number) {
    return new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "BRL",
    }).format(value);
  }

  return {
    toast,
    activeRole,
    clearToast,
    showToast,
    copyText,
    share,
    money,
  };
}
