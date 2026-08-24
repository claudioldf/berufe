import Bugsnag from "@bugsnag/js";
import {
  bugsnagRedactedKeys,
  notifyBugsnagError,
  removePrivateDiagnostics,
} from "../../app/utils/bugsnag";

export default defineNitroPlugin((nitroApp) => {
  const config = useRuntimeConfig();
  const apiKey = config.public.bugsnagApiKey;

  if (!apiKey || import.meta.dev) return;

  if (!Bugsnag.isStarted()) {
    Bugsnag.start({
      apiKey,
      appVersion: config.public.releaseVersion || undefined,
      autoTrackSessions: false,
      enabledBreadcrumbTypes: [],
      redactedKeys: bugsnagRedactedKeys,
      releaseStage: "production",
      onError: removePrivateDiagnostics,
    });
  }

  nitroApp.hooks.hook("error", (error) => {
    notifyBugsnagError(error, "nitro");
  });
});
