import { useApplicationSession } from "~/composables/useApplicationSession";

const professionalLoginPath = "/app/professional/login";

function requiresApplicationSession(path: string) {
  return (
    path.startsWith("/app/admin") ||
    (path.startsWith("/app/professional") && path !== professionalLoginPath)
  );
}

export default defineNuxtRouteMiddleware(async (to) => {
  if (typeof window === "undefined" || !requiresApplicationSession(to.path)) {
    return;
  }

  const { restoreSession } = useApplicationSession();
  if (!(await restoreSession())) {
    return navigateTo(professionalLoginPath, { replace: true });
  }
});

export { requiresApplicationSession };
