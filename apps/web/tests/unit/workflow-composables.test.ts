import { effectScope, nextTick } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import moderationData from "@data/moderation.json";
import professionalsData from "@data/professionals.json";
import type { ModerationQueueItem, Professional } from "~/types";
import { useModerationQueue } from "~/composables/useModerationQueue";
import { usePhoneAuthFlow } from "~/composables/usePhoneAuthFlow";
import { useProfessionalProfileDraft } from "~/composables/useProfessionalProfileDraft";
import { PhoneOtpRequestError } from "~/services/api/phone-auth";

afterEach(() => {
  vi.useRealTimers();
});

describe("moderation queue", () => {
  it("filters searchable fields and advances selection after a decision", async () => {
    const workflow = useModerationQueue(
      moderationData.queue as ModerationQueueItem[],
    );
    workflow.searchQuery.value = "verificação";
    await nextTick();
    expect(workflow.filteredQueue.value.length).toBeGreaterThan(0);
    expect(
      workflow.filteredQueue.value.every((item) =>
        `${item.type} ${item.title}`
          .toLocaleLowerCase("pt-BR")
          .includes("verificação"),
      ),
    ).toBe(true);

    const decided = workflow.decide();
    expect(decided).not.toBeNull();
    expect(workflow.queue.value).not.toContainEqual(decided);
  });
});

describe("profile drafts", () => {
  it("clones arrays and returns a normalized typed payload", () => {
    const professional = (professionalsData as Professional[])[0]!;
    const workflow = useProfessionalProfileDraft(professional);
    workflow.form.instagram = "@berufe";
    const draft = workflow.commit();

    expect(draft?.instagram).toBe("https://www.instagram.com/berufe/");
    expect(draft?.selectedServices).not.toBe(professional.services);
  });
});

describe("phone authentication", () => {
  it("requests a normalized OTP, owns progression, and clears timers", async () => {
    vi.useFakeTimers();
    const scope = effectScope();
    const requestOtp = vi.fn().mockResolvedValue({
      challengeToken: "browser-challenge-token",
      expiresIn: 600,
      resendAvailableIn: 30,
    });
    const workflow = scope.run(() => usePhoneAuthFlow({ requestOtp }))!;

    expect(workflow.phone.value).toBe("");
    expect(workflow.name.value).toBe("");
    workflow.phone.value = "(47) 99999-1111";
    await workflow.requestCode();

    expect(requestOtp).toHaveBeenCalledWith("+5547999991111");
    expect(workflow.phone.value).toBe("(47) 99999-1111");
    expect(workflow.step.value).toBe(2);
    expect(workflow.cooldown.value).toBe(30);
    expect(workflow.challengeToken.value).toBe("browser-challenge-token");
    await workflow.requestCode();
    expect(requestOtp).toHaveBeenCalledTimes(1);

    workflow.code.value = "000000";
    workflow.verifyCode();
    expect(workflow.error.value).toBe("Código inválido ou expirado.");

    workflow.code.value = "123456";
    workflow.verifyCode();
    workflow.verifyCode();
    vi.advanceTimersByTime(650);
    expect(workflow.step.value).toBe(3);

    vi.advanceTimersByTime(29_350);
    expect(workflow.cooldown.value).toBe(0);

    workflow.changePhone();
    expect(workflow.step.value).toBe(1);
    expect(workflow.code.value).toBe("");
    expect(workflow.challengeToken.value).toBe("");

    expect(workflow.validateRegistration()).toBe(false);
    expect(workflow.error.value).toBe("Informe seu nome profissional.");
    workflow.name.value = "Ana";
    expect(workflow.validateRegistration()).toBe(false);
    expect(workflow.error.value).toContain("aceitar os termos");
    workflow.accepted.value = true;
    expect(workflow.validateRegistration()).toBe(true);

    scope.stop();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("rejects invalid phones locally and surfaces contracted request failures", async () => {
    vi.useFakeTimers();
    const requestOtp = vi
      .fn()
      .mockRejectedValueOnce(
        new PhoneOtpRequestError(
          {
            code: "otp_rate_limited",
            message: "Aguarde antes de pedir outro código.",
            fieldErrors: {},
            requestId: "otp-429",
          },
          18,
        ),
      )
      .mockRejectedValueOnce(
        new PhoneOtpRequestError(
          {
            code: "otp_rate_limited",
            message: "Aguarde novamente.",
            fieldErrors: {},
            requestId: "otp-429-again",
          },
          10,
        ),
      )
      .mockRejectedValueOnce(new Error("network details"));
    const scope = effectScope();
    const workflow = scope.run(() => usePhoneAuthFlow({ requestOtp }))!;

    workflow.phone.value = "47 3333-1111";
    await workflow.requestCode();
    expect(workflow.error.value).toBe("Digite um número brasileiro válido.");
    expect(requestOtp).not.toHaveBeenCalled();

    workflow.phone.value = "47999991111";
    await workflow.requestCode();
    expect(workflow.error.value).toBe("Aguarde antes de pedir outro código.");
    expect(workflow.cooldown.value).toBe(18);

    await workflow.requestCode();
    expect(workflow.error.value).toBe("Aguarde novamente.");
    expect(workflow.cooldown.value).toBe(10);

    vi.advanceTimersByTime(10_000);
    expect(workflow.cooldown.value).toBe(0);

    await workflow.requestCode();
    expect(workflow.error.value).toBe(
      "Não foi possível enviar o código agora. Tente novamente em instantes.",
    );

    scope.stop();
  });

  it("ignores duplicate submissions while a request is pending", async () => {
    vi.useFakeTimers();
    let resolveRequest:
      | ((value: {
          challengeToken: string;
          expiresIn: number;
          resendAvailableIn: number;
        }) => void)
      | undefined;
    const requestOtp = vi.fn(
      () =>
        new Promise<{
          challengeToken: string;
          expiresIn: number;
          resendAvailableIn: number;
        }>((resolve) => {
          resolveRequest = resolve;
        }),
    );
    const scope = effectScope();
    const workflow = scope.run(() => usePhoneAuthFlow({ requestOtp }))!;
    workflow.phone.value = "47999991111";

    const firstRequest = workflow.requestCode();
    await workflow.requestCode();
    expect(requestOtp).toHaveBeenCalledTimes(1);

    resolveRequest?.({
      challengeToken: "browser-challenge-token",
      expiresIn: 600,
      resendAvailableIn: 30,
    });
    await firstRequest;
    workflow.code.value = "123456";
    workflow.verifyCode();

    scope.stop();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("uses the production API dependency by default and keeps transport details safe", async () => {
    const scope = effectScope();
    const workflow = scope.run(() => usePhoneAuthFlow())!;
    workflow.phone.value = "47999991111";

    await workflow.requestCode();

    expect(workflow.error.value).toBe(
      "Não foi possível enviar o código agora. Tente novamente em instantes.",
    );
    scope.stop();
  });
});
