import { useApplicationSession } from "~/composables/useApplicationSession";

const professionalLoginPath = "/app/professional/login";
const adminLoginPath = "/app/admin/login";
type WorkspaceRole = "professional" | "admin";

function requiredWorkspaceRole(path: string): WorkspaceRole | undefined {
  if (path.startsWith("/app/admin") && path !== adminLoginPath) return "admin";
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

  const { account, session, restoreSession } = useApplicationSession();
  const requiredRole = requiredWorkspaceRole(to.path);
  if (!(await restoreSession())) {
    return navigateTo(
      requiredRole === "admin" ? adminLoginPath : professionalLoginPath,
      { replace: true },
    );
  }

  if (requiredRole && account.value?.role !== requiredRole) {
    return navigateTo(
      account.value?.role === "admin" ? "/app/admin" : "/app/professional",
      { replace: true },
    );
  }

  if (
    requiredRole === "admin" &&
    session.value?.authenticationMethod !== "password"
  ) {
    return navigateTo(adminLoginPath, { replace: true });
  }

  if (
    requiredRole === "professional" &&
    account.value?.registrationCompleted === false
  ) {
    return navigateTo(professionalLoginPath, { replace: true });
  }
});

export {
  adminLoginPath,
  professionalLoginPath,
  requiredWorkspaceRole,
  requiresApplicationSession,
};
