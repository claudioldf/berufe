import Bugsnag from "@bugsnag/js";
import type { Event } from "@bugsnag/js";
import BugsnagPluginVue from "@bugsnag/plugin-vue";

const redactedKeys = [
  /authorization/i,
  /body/i,
  /challenge/i,
  /cookie/i,
  /customer/i,
  /email/i,
  /file/i,
  /header/i,
  /otp/i,
  /param/i,
  /password/i,
  /phone/i,
  /secret/i,
  /session/i,
  /signed/i,
  /token/i,
  /url/i,
];

type SerializableBugsnagEvent = {
  toJSON(): { metaData?: Record<string, unknown> };
};

function removePrivateDiagnostics(event: Event) {
  const metadata = (event as unknown as SerializableBugsnagEvent).toJSON()
    .metaData;

  for (const section of Object.keys(metadata ?? {})) {
    event.clearMetadata(section);
  }

  event.setUser();
  event.breadcrumbs.length = 0;
  event.request = {};
  event.response = {
    statusCode: event.response.statusCode,
    headers: {},
  };
}

export default defineNuxtPlugin((nuxtApp) => {
  const config = useRuntimeConfig();
  const apiKey = config.public.bugsnagApiKey;

  if (!apiKey || import.meta.dev) return;

  Bugsnag.start({
    apiKey,
    appVersion: config.public.releaseVersion || undefined,
    autoTrackSessions: false,
    collectUserIp: false,
    enabledBreadcrumbTypes: [],
    generateAnonymousId: false,
    plugins: [new BugsnagPluginVue()],
    redactedKeys,
    releaseStage: "production",
    onError(event) {
      removePrivateDiagnostics(event);
      event.context =
        nuxtApp.$router.currentRoute.value.matched.at(-1)?.path ?? "nuxt";
    },
  });

  const vuePlugin = Bugsnag.getPlugin("vue");
  if (vuePlugin) nuxtApp.vueApp.use(vuePlugin);
});
