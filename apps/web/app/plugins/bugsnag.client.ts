import Bugsnag from "@bugsnag/js";
import BugsnagPluginVue from "@bugsnag/plugin-vue";
import {
  bugsnagRedactedKeys,
  normalizeBugsnagContext,
  notifyBugsnagError,
  removePrivateDiagnostics,
} from "@app/utils/bugsnag";

export default defineNuxtPlugin((nuxtApp) => {
  const config = useRuntimeConfig();
  const apiKey = config.public.bugsnagApiKey;

  if (!apiKey || import.meta.dev || Bugsnag.isStarted()) return;
  const currentContext = () => {
    const routeName = nuxtApp.$router.currentRoute.value.name;
    return normalizeBugsnagContext(
      routeName ? `nuxt:${String(routeName)}` : "nuxt",
    );
  };

  Bugsnag.start({
    apiKey,
    appVersion: config.public.releaseVersion || undefined,
    autoTrackSessions: false,
    collectUserIp: false,
    enabledBreadcrumbTypes: [],
    generateAnonymousId: false,
    plugins: [new BugsnagPluginVue()],
    redactedKeys: bugsnagRedactedKeys,
    releaseStage: "production",
    onError(event) {
      removePrivateDiagnostics(event);
      event.context = currentContext();
    },
  });

  const vuePlugin = Bugsnag.getPlugin("vue");
  if (vuePlugin) nuxtApp.vueApp.use(vuePlugin);

  nuxtApp.hook("app:error", (error) => {
    notifyBugsnagError(error, currentContext());
  });
  nuxtApp.hook("vue:error", (error) => {
    notifyBugsnagError(error, currentContext());
  });
});
