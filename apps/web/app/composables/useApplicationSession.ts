import { readonly } from "vue";
import {
  endCurrentApplicationSession,
  getCurrentApplicationSession,
  type CurrentAccount,
  type CurrentSession,
  type RestoredApplicationSession,
} from "~/services/api/application-session";
import { useApiClient } from "~/services/api/client";
import { clearProfessionalNotificationState } from "~/composables/useProfessionalNotificationState";

type SessionStatus = "unknown" | "restoring" | "authenticated" | "anonymous";

interface ApplicationSessionDependencies {
  read?: () => Promise<RestoredApplicationSession | null>;
  end?: () => Promise<void>;
}

let restoration: Promise<boolean> | undefined;

export function useApplicationSession(
  dependencies: ApplicationSessionDependencies = {},
) {
  const { setRole } = useAppRole();
  const account = useState<CurrentAccount | null>(
    "application-session-account",
    () => null,
  );
  const session = useState<CurrentSession | null>(
    "application-session-summary",
    () => null,
  );
  const status = useState<SessionStatus>(
    "application-session-status",
    () => "unknown",
  );
  const isEnding = useState<boolean>(
    "application-session-is-ending",
    () => false,
  );
  const read =
    dependencies.read ?? (() => getCurrentApplicationSession(useApiClient()));
  const end =
    dependencies.end ?? (() => endCurrentApplicationSession(useApiClient()));

  function resetSession(nextStatus: SessionStatus) {
    clearProfessionalNotificationState();
    account.value = null;
    session.value = null;
    status.value = nextStatus;
    setRole("visitor");
  }

  function clearSession() {
    resetSession("anonymous");
  }

  function replaceSession(restored: RestoredApplicationSession) {
    if (account.value?.id !== restored.account.id) {
      clearProfessionalNotificationState();
    }
    account.value = restored.account;
    session.value = restored.session;
    status.value = "authenticated";
    setRole(restored.account.role);
  }

  async function restoreSession(): Promise<boolean> {
    if (status.value === "authenticated") return true;
    if (status.value === "anonymous") return false;
    if (restoration) return restoration;

    status.value = "restoring";
    restoration = (async () => {
      try {
        const restored = await read();
        if (!restored) {
          resetSession("anonymous");
          return false;
        }

        replaceSession(restored);
        return true;
      } catch (error) {
        resetSession("unknown");
        throw error;
      } finally {
        restoration = undefined;
      }
    })();

    return restoration;
  }

  async function refreshSession(): Promise<boolean> {
    if (restoration) {
      try {
        await restoration;
      } catch {
        // A refresh must retry after an overlapping stale restoration fails.
      }
    }
    status.value = "unknown";
    return restoreSession();
  }

  async function logout(): Promise<void> {
    if (isEnding.value) return;

    isEnding.value = true;
    try {
      await end();
      clearSession();
    } finally {
      isEnding.value = false;
    }
  }

  return {
    account: readonly(account),
    session: readonly(session),
    status: readonly(status),
    isEnding: readonly(isEnding),
    restoreSession,
    refreshSession,
    logout,
    clearSession,
    replaceSession,
  };
}
