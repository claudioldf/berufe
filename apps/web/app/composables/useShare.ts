import { useToast } from "~/composables/useToast";

interface ShareOptions {
  title: string;
  text: string;
  url: string;
}

export function useShare() {
  const { showToast } = useToast();

  async function copyText(value: string, message = "Link copiado") {
    try {
      if (!import.meta.client || !navigator.clipboard) {
        throw new Error("Clipboard unavailable");
      }
      await navigator.clipboard.writeText(value);
      showToast({
        title: message,
        description: "Pronto para você compartilhar.",
      });
      return true;
    } catch {
      showToast({
        title: "Não foi possível copiar",
        description: "Copie o endereço diretamente pela barra do navegador.",
      });
      return false;
    }
  }

  async function share(options: ShareOptions) {
    if (import.meta.client && navigator.share) {
      try {
        await navigator.share(options);
        return true;
      } catch (error) {
        if (error instanceof DOMException && error.name === "AbortError") {
          return false;
        }
      }
    }
    return copyText(options.url);
  }

  return { copyText, share };
}
