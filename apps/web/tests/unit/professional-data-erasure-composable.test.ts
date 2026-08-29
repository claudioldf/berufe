import { effectScope } from "vue";
import { ApiRequestError } from "~/services/api/errors";
import { useProfessionalDataErasure } from "~/composables/useProfessionalDataErasure";

const mocks = vi.hoisted(() => ({
  clearSession: vi.fn(),
}));

vi.mock("~/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({
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
});

describe("professional data erasure workflow", () => {
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

    const first = workflow.submit();
    await expect(workflow.submit()).resolves.toBeNull();
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
        code: "erasure_request_unavailable",
        message: "Não foi possível registrar a solicitação agora.",
        fieldErrors: {},
        requestId: "erasure-503",
      }),
    );
    const scope = effectScope();
    const workflow = scope.run(() => useProfessionalDataErasure({ request }))!;

    await expect(workflow.submit()).resolves.toBeNull();
    expect(workflow.error.value).toBe(
      "Não foi possível registrar a solicitação agora.",
    );
    expect(mocks.clearSession).not.toHaveBeenCalled();
    scope.stop();
  });
});
