import { useApplicationSession } from "~/composables/useApplicationSession";
import { matchSearchAction } from "~/utils/search-actions";

interface SearchActionNavigationDependencies {
  /** Resolves true when a professional is signed in. Injected by tests. */
  isProfessionalSignedIn?: () => Promise<boolean>;
}

export function useSearchActionNavigation(
  dependencies: SearchActionNavigationDependencies = {},
) {
  const { account, restoreSession } = useApplicationSession();
  const isProfessionalSignedIn =
    dependencies.isProfessionalSignedIn ??
    (async () => {
      try {
        return (
          (await restoreSession()) && account.value?.role === "professional"
        );
      } catch {
        return false;
      }
    });

  /**
   * Where a search for an account action should go: the workspace page for a
   * signed-in professional, the help page for everyone else, or `null` when
   * the expression is an ordinary service search. The session is only
   * consulted in the browser; during SSR the help page is always correct.
   */
  async function resolveSearchAction(
    expression: string,
  ): Promise<string | null> {
    const action = matchSearchAction(expression);
    if (!action) return null;
    if (!import.meta.client) return action.helpPath;

    return (await isProfessionalSignedIn()) ? action.appPath : action.helpPath;
  }

  return { resolveSearchAction };
}
