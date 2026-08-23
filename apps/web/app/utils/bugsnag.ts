import Bugsnag from "@bugsnag/js";
import type { Event } from "@bugsnag/js";

export const bugsnagRedactedKeys = [
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

const safeContextPattern = /^[A-Za-z0-9_:/{}.-]{1,200}$/;
const reportedErrors = new WeakSet<object>();

type SerializableBugsnagEvent = {
  toJSON(): { metaData?: Record<string, unknown> };
};

export function normalizeBugsnagContext(
  value: unknown,
  fallback = "nuxt",
): string {
  return typeof value === "string" && safeContextPattern.test(value)
    ? value
    : fallback;
}

export function removePrivateDiagnostics(event: Event): boolean {
  const metadata = (event as unknown as SerializableBugsnagEvent).toJSON()
    .metaData;

  for (const section of Object.keys(metadata ?? {})) {
    event.clearMetadata(section);
  }

  const statusCode = event.response?.statusCode;
  event.setUser();
  event.breadcrumbs.length = 0;
  event.request = {};
  event.response = { statusCode: statusCode ?? 0, headers: {} };
  event.context = normalizeBugsnagContext(event.context);
  return true;
}

export function notifyBugsnagError(error: unknown, context: string): boolean {
  if (!Bugsnag.isStarted()) return false;

  if (
    error !== null &&
    (typeof error === "object" || typeof error === "function")
  ) {
    if (reportedErrors.has(error)) return false;
    reportedErrors.add(error);
  }

  const reportableError =
    error instanceof Error ? error : new Error("Non-Error exception");
  const safeContext = normalizeBugsnagContext(context);
  try {
    Bugsnag.notify(reportableError, (event) => {
      event.context = safeContext;
      return true;
    });
    return true;
  } catch {
    return false;
  }
}

export function apiBugsnagContext(method: string, schemaPath: string): string {
  return normalizeBugsnagContext(`api:${method.toUpperCase()}:${schemaPath}`);
}
