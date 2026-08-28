import { useApplicationSession } from "~/composables/useApplicationSession";
import {
  professionalDashboardPath,
  professionalLoginPath,
  professionalOnboardingPath,
  resolveProfessionalEntryPath,
} from "~/utils/professional-auth";

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

export default defineNuxtRouteMiddleware(async (to, from) => {
  const requiredRole = requiredWorkspaceRole(to.path);
  const isProfessionalAuthRoute = to.path === professionalLoginPath;
  if (
    typeof window === "undefined" ||
    (!requiredRole && !isProfessionalAuthRoute)
  ) {
    return;
  }

  const { account, session, restoreSession } = useApplicationSession();
  let authenticated: boolean;
  try {
    authenticated = await restoreSession();
  } catch (error) {
    if (isProfessionalAuthRoute) return;
    throw error;
  }

  if (!authenticated) {
    if (isProfessionalAuthRoute) return;
    return navigateTo(
      requiredRole === "admin" ? adminLoginPath : professionalLoginPath,
      { replace: true },
    );
  }

  if (isProfessionalAuthRoute) {
    if (account.value?.role !== "professional") return;
    const destination = resolveProfessionalEntryPath(account.value);
    if (destination !== professionalLoginPath) {
      return navigateTo(destination, { replace: true });
    }
    return;
  }

  if (requiredRole && account.value?.role !== requiredRole) {
    return navigateTo(
      account.value?.role === "admin"
        ? "/app/admin"
        : professionalDashboardPath,
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

  if (
    to.path === professionalOnboardingPath &&
    account.value?.onboardingCompleted &&
    from.path !== professionalOnboardingPath
  ) {
    return navigateTo(professionalDashboardPath, { replace: true });
  }
});

export {
  adminLoginPath,
  professionalLoginPath,
  requiredWorkspaceRole,
  requiresApplicationSession,
};
