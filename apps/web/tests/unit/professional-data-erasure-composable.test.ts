import { effectScope, ref } from "vue";
import type { Ref } from "vue";
import { ApiRequestError } from "~/services/api/errors";
import { useProfessionalDataErasure } from "~/composables/useProfessionalDataErasure";

const mocks = vi.hoisted(() => ({
  session: undefined as
    | Ref<{
        authenticationMethod: "sms_otp" | "password";
        authenticatedAt: string;
      } | null>
    | undefined,
  clearSession: vi.fn(),
}));

vi.mock("~/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({
    session: mocks.session!,
    clearSession: mocks.clearSession,
  }),
}));

const submittedRequest = {
  statusToken: "be_status-token",
  request: {
    reference: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
    status: "requested" as const,
    requestedAt: "2026-08-29T15:00:00.000Z",
    unpublishedAt: "2026-08-29T15:00:00.000Z",
    completionDeadlineAt: "2026-09-28T15:00:00.000Z",
    completedAt: null,
  },
};

beforeEach(() => {
  vi.clearAllMocks();
  mocks.session = ref(null);
});

describe("professional data erasure workflow", () => {
  it("derives the 30-minute SMS reauthentication window", () => {
    vi.useFakeTimers();
    let now = Date.parse("2026-08-29T15:00:00.000Z");
    const scope = effectScope();
    const workflow = scope.run(() =>
      useProfessionalDataErasure({ now: () => now }),
    )!;

    expect(workflow.isRecentlyVerified.value).toBe(false);
    mocks.session!.value = {
      authenticationMethod: "sms_otp",
      authenticatedAt: "2026-08-29T14:30:00.000Z",
    };
    expect(workflow.isRecentlyVerified.value).toBe(true);
    now += 1_001;
    vi.advanceTimersByTime(1_000);
    expect(workflow.isRecentlyVerified.value).toBe(false);
    scope.stop();
    vi.useRealTimers();
  });

  it("prevents duplicate submissions and clears local auth after acceptance", async () => {
    let resolveRequest: ((value: typeof submittedRequest) => void) | undefined;
    const request = vi.fn(
      () =>
        new Promise<typeof submittedRequest>((resolve) => {
          resolveRequest = resolve;
        }),
    );
    const scope = effectScope();
    const workflow = scope.run(() => useProfessionalDataErasure({ request }))!;

    const first = workflow.submit("EXCLUIR");
    await expect(workflow.submit("EXCLUIR")).resolves.toBeNull();
    expect(request).toHaveBeenCalledOnce();
    expect(workflow.submitting.value).toBe(true);

    resolveRequest?.(submittedRequest);
    await expect(first).resolves.toEqual(submittedRequest);
    expect(mocks.clearSession).toHaveBeenCalledOnce();
    expect(workflow.submitting.value).toBe(false);
    scope.stop();
  });

  it("keeps contracted errors safe and leaves the session available to retry", async () => {
    const request = vi.fn().mockRejectedValue(
      new ApiRequestError({
        code: "recent_verification_required",
        message: "Confirme seu telefone por SMS novamente para continuar.",
        fieldErrors: {},
        requestId: "erasure-428",
      }),
    );
    const scope = effectScope();
    const workflow = scope.run(() => useProfessionalDataErasure({ request }))!;

    await expect(workflow.submit("EXCLUIR")).resolves.toBeNull();
    expect(workflow.error.value).toBe(
      "Confirme seu telefone por SMS novamente para continuar.",
    );
    expect(mocks.clearSession).not.toHaveBeenCalled();
    scope.stop();
  });
});
