import { readonly } from "vue";
import {
  endCurrentApplicationSession,
  getCurrentApplicationSession,
  type CurrentAccount,
  type CurrentSession,
  type RestoredApplicationSession,
} from "~/services/api/application-session";
import { setApiCsrfToken, useApiClient } from "~/services/api/client";

type SessionStatus = "unknown" | "restoring" | "authenticated" | "anonymous";

interface ApplicationSessionDependencies {
  read?: () => Promise<RestoredApplicationSession | null>;
  end?: () => Promise<void>;
  setCsrfToken?: (token: string | undefined) => void;
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
  const updateCsrfToken = dependencies.setCsrfToken ?? setApiCsrfToken;

  function resetSession(nextStatus: SessionStatus) {
    account.value = null;
    session.value = null;
    status.value = nextStatus;
    setRole("visitor");
    updateCsrfToken(undefined);
  }

  function clearSession() {
    resetSession("anonymous");
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

        account.value = restored.account;
        session.value = restored.session;
        status.value = "authenticated";
        setRole(restored.account.role);
        updateCsrfToken(restored.csrfToken);
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
    logout,
    clearSession,
  };
}
