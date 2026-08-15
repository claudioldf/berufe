import { useApplicationSession } from "~/composables/useApplicationSession";

const professionalLoginPath = "/app/professional/login";
type WorkspaceRole = "professional" | "admin";

function requiredWorkspaceRole(path: string): WorkspaceRole | undefined {
  if (path.startsWith("/app/admin")) return "admin";
  if (path.startsWith("/app/professional") && path !== professionalLoginPath) {
    return "professional";
  }
}

function requiresApplicationSession(path: string) {
  return requiredWorkspaceRole(path) !== undefined;
}

export default defineNuxtRouteMiddleware(async (to) => {
  if (typeof window === "undefined" || !requiresApplicationSession(to.path)) {
    return;
  }

  const { account, restoreSession } = useApplicationSession();
  if (!(await restoreSession())) {
    return navigateTo(professionalLoginPath, { replace: true });
  }

  const requiredRole = requiredWorkspaceRole(to.path);
  if (requiredRole && account.value?.role !== requiredRole) {
    return navigateTo(
      account.value?.role === "admin" ? "/app/admin" : "/app/professional",
      { replace: true },
    );
  }

  if (
    requiredRole === "professional" &&
    account.value?.registrationCompleted === false
  ) {
    return navigateTo(professionalLoginPath, { replace: true });
  }
});

export { requiredWorkspaceRole, requiresApplicationSession };
