import { readonly, shallowRef } from "vue";
import {
  startAdminProfessionalImpersonation,
  stopAdminProfessionalImpersonation,
} from "~/services/api/admin-impersonation";
import { useApiClient } from "~/services/api/client";
import type { RestoredApplicationSession } from "~/services/api/application-session";
import { clearProfessionalNotificationState } from "~/composables/useProfessionalNotificationState";
import type { AdminProfessionalItem } from "~/types";

const returnPathKey = "berufe:admin-impersonation:return-path";
const fallbackReturnPath = "/app/admin/professionals";

interface AdminImpersonationDependencies {
  start?: (
    professionalAccountId: string,
  ) => Promise<RestoredApplicationSession>;
  stop?: () => Promise<RestoredApplicationSession>;
  replaceSession?: (restored: RestoredApplicationSession) => void;
  route?: { fullPath: string };
  router?: { replace: (path: string) => Promise<unknown> };
  storage?: Pick<Storage, "getItem" | "removeItem" | "setItem">;
  clearProfessionalData?: () => Promise<void> | void;
}

export function useAdminImpersonation(
  dependencies: AdminImpersonationDependencies = {},
) {
  const client = useApiClient();
  const applicationSession = useApplicationSession();
  const route = dependencies.route ?? useRoute();
  const router = dependencies.router ?? useRouter();
  const storage =
    dependencies.storage ??
    (import.meta.client ? window.sessionStorage : undefined);
  const isChanging = useState<boolean>(
    "admin-impersonation-is-changing",
    () => false,
  );
  // Per-instance: a failed start/stop should not leave a stale alert visible
  // after navigating to a freshly mounted directory or banner.
  const error = shallowRef("");
  const startRequest =
    dependencies.start ??
    ((professionalAccountId) =>
      startAdminProfessionalImpersonation(client, professionalAccountId));
  const stopRequest =
    dependencies.stop ?? (() => stopAdminProfessionalImpersonation(client));
  const replaceSession =
    dependencies.replaceSession ?? applicationSession.replaceSession;
  const clearProfessionalData =
    dependencies.clearProfessionalData ??
    (() => {
      clearProfessionalNotificationState();
      return clearNuxtData((key) => key.startsWith("professional-"));
    });

  function rememberReturnPath() {
    if (route.fullPath.startsWith(fallbackReturnPath)) {
      storage?.setItem(returnPathKey, route.fullPath);
    }
  }

  function consumeReturnPath() {
    const stored = storage?.getItem(returnPathKey);
    storage?.removeItem(returnPathKey);
    return stored?.startsWith(fallbackReturnPath) ? stored : fallbackReturnPath;
  }

  async function start(item: AdminProfessionalItem) {
    if (!item.impersonationEligible || isChanging.value) return false;

    isChanging.value = true;
    error.value = "";
    rememberReturnPath();
    try {
      const restored = await startRequest(item.id);
      replaceSession(restored);
      await clearProfessionalData();
      await router.replace("/app/professional");
      return true;
    } catch (cause) {
      error.value =
        cause instanceof Error
          ? cause.message
          : "Não foi possível gerenciar esta conta agora.";
      return false;
    } finally {
      isChanging.value = false;
    }
  }

  async function stop() {
    if (isChanging.value) return false;

    isChanging.value = true;
    error.value = "";
    try {
      const restored = await stopRequest();
      replaceSession(restored);
      await clearProfessionalData();
      await router.replace(consumeReturnPath());
      return true;
    } catch (cause) {
      error.value =
        cause instanceof Error
          ? cause.message
          : "Não foi possível voltar ao painel administrativo agora.";
      return false;
    } finally {
      isChanging.value = false;
    }
  }

  return {
    isChanging: readonly(isChanging),
    error: readonly(error),
    start,
    stop,
  };
}
