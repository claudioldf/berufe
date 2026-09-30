import { effectScope, nextTick } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import professionalsData from "@data/professionals.json";
import type { Professional } from "~/types";
import { useProfessionalAuthFlow } from "~/composables/useProfessionalAuthFlow";
import {
  useProfessionalProfileDraft,
  validateProfessionalProfileDraft,
} from "~/composables/useProfessionalProfileDraft";
import { ProfessionalOtpRequestError } from "~/services/api/phone-auth";
import { ApiRequestError } from "~/services/api/errors";

afterEach(() => {
  vi.useRealTimers();
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

  it("mirrors the complete profile rules before persistence", () => {
    const professional = (professionalsData as Professional[])[0]!;
    const workflow = useProfessionalProfileDraft(professional);
    Object.assign(workflow.form, {
      name: "A",
      birthdate: "2030-01-01",
      whatsapp: "47 3333-1111",
      yearsExperience: 71,
      selectedServices: [],
      primaryService: "",
      coverageCityCode: "",
      coversWholeCity: false,
      selectedNeighborhoodCodes: [],
    });

    const validation = validateProfessionalProfileDraft(workflow.form);

    expect(validation.identity.name).toContain("3 caracteres");
    expect(validation.identity.birthdate).toContain("válida");
    expect(validation.identity.whatsapp).toContain("celular brasileiro");
    expect(validation.identity.yearsExperience).toContain("0 e 70");
    expect(validation.services).toContain("serviço");
    expect(validation.coverage).toContain("cidade inteira");
  });

  it("normalizes and reassigns the featured service in profile drafts", () => {
    const source = (professionalsData as Professional[])[0]!;
    const professional: Professional = {
      ...source,
      services: ["Eletricista", "Diarista"],
      serviceNotes: ["Quadros", "Limpeza residencial"],
      primaryService: "",
    };
    const workflow = useProfessionalProfileDraft(professional);

    expect(workflow.form.primaryService).toBe("Eletricista");

    workflow.toggleService("Eletricista");
    expect(workflow.form.selectedServices).toEqual(["Diarista"]);
    expect(workflow.form.primaryService).toBe("Diarista");

    workflow.form.primaryService = "";
    expect(workflow.commit()?.primaryService).toBe("Diarista");
  });
});

describe("professional authentication", () => {
  it("requests a normalized OTP, owns progression, and clears timers", async () => {
    vi.useFakeTimers();
    const scope = effectScope();
    const requestOtp = vi.fn().mockResolvedValue({
      challengeToken: "browser-challenge-token",
      expiresIn: 600,
      resendAvailableIn: 30,
    });
    let resolveVerification: (() => void) | undefined;
    const verifyOtp = vi.fn(
      () =>
        new Promise<void>((resolve) => {
          resolveVerification = resolve;
        }),
    );
    let resolveRegistration: (() => void) | undefined;
    const completeRegistration = vi.fn(
      () =>
        new Promise<void>((resolve) => {
          resolveRegistration = resolve;
        }),
    );
    const workflow = scope.run(() =>
      useProfessionalAuthFlow({ requestOtp, verifyOtp, completeRegistration }),
    )!;

    expect(workflow.phone.value).toBe("");
    expect(workflow.name.value).toBe("");
    workflow.phone.value = "(47) 99999-1111";
    await workflow.requestCode();

    expect(requestOtp).toHaveBeenCalledWith({
      method: "phone",
      identifier: "+5547999991111",
    });
    expect(workflow.phone.value).toBe("(47) 9 9999-1111");
    expect(workflow.step.value).toBe(2);
    expect(workflow.cooldown.value).toBe(30);
    expect(workflow.challengeToken.value).toBe("browser-challenge-token");
    await workflow.requestCode();
    expect(requestOtp).toHaveBeenCalledTimes(1);

    workflow.code.value = "12ab56";
    await expect(workflow.verifyCode()).resolves.toBe(false);
    expect(workflow.error.value).toBe("Código inválido ou expirado.");
    expect(verifyOtp).not.toHaveBeenCalled();

    workflow.code.value = "123456";
    const firstVerification = workflow.verifyCode();
    await expect(workflow.verifyCode()).resolves.toBe(false);
    expect(verifyOtp).toHaveBeenCalledOnce();
    expect(verifyOtp).toHaveBeenCalledWith({
      challengeToken: "browser-challenge-token",
      code: "123456",
    });
    resolveVerification?.();
    await expect(firstVerification).resolves.toBe(true);
    expect(workflow.step.value).toBe(2);
    expect(workflow.challengeToken.value).toBe("");

    vi.advanceTimersByTime(30_000);
    expect(workflow.cooldown.value).toBe(0);

    workflow.changeDestination();
    expect(workflow.step.value).toBe(1);
    expect(workflow.code.value).toBe("");
    expect(workflow.challengeToken.value).toBe("");

    expect(workflow.validateRegistration()).toBe(false);
    expect(workflow.error.value).toBe("Informe seu nome profissional.");
    workflow.name.value = "Ana";
    expect(workflow.validateRegistration()).toBe(false);
    expect(workflow.error.value).toBe("Digite um e-mail válido.");
    workflow.email.value = " ANA@Example.COM ";
    expect(workflow.validateRegistration()).toBe(false);
    expect(workflow.error.value).toContain("aceitar os termos");
    workflow.accepted.value = true;
    expect(workflow.validateRegistration()).toBe(true);

    workflow.name.value = "  Ana Reparos  ";
    const registration = workflow.registerProfessional();
    await expect(workflow.registerProfessional()).resolves.toBe(false);
    expect(completeRegistration).toHaveBeenCalledOnce();
    expect(completeRegistration).toHaveBeenCalledWith({
      displayName: "Ana Reparos",
      accepted: true,
      method: "phone",
      email: "ana@example.com",
    });
    resolveRegistration?.();
    await expect(registration).resolves.toBe(true);

    workflow.resumeRegistration();
    expect(workflow.step.value).toBe(3);
    expect(workflow.code.value).toBe("");
    expect(workflow.challengeToken.value).toBe("");

    scope.stop();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("rejects invalid phones locally and surfaces contracted request failures", async () => {
    vi.useFakeTimers();
    const requestOtp = vi
      .fn()
      .mockRejectedValueOnce(
        new ProfessionalOtpRequestError(
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
        new ProfessionalOtpRequestError(
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
    const workflow = scope.run(() => useProfessionalAuthFlow({ requestOtp }))!;

    workflow.phone.value = "47 3333-1111";
    await workflow.requestCode();
    expect(workflow.error.value).toBe("Digite um número de celular válido.");
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

  it("uses email as an alternate OTP destination while keeping phone default", async () => {
    vi.useFakeTimers();
    const requestOtp = vi.fn().mockResolvedValue({
      challengeToken: "email-browser-challenge-token",
      expiresIn: 600,
      resendAvailableIn: 30,
    });
    const completeRegistration = vi.fn().mockResolvedValue(undefined);
    const scope = effectScope();
    const workflow = scope.run(() =>
      useProfessionalAuthFlow({ requestOtp, completeRegistration }),
    )!;

    expect(workflow.method.value).toBe("phone");
    workflow.method.value = "email";
    await nextTick();
    workflow.email.value = "email-invalido";
    await workflow.requestCode();
    expect(workflow.error.value).toBe("Digite um e-mail válido.");
    expect(requestOtp).not.toHaveBeenCalled();

    workflow.email.value = " ANA@Example.COM ";
    await workflow.requestCode();

    expect(requestOtp).toHaveBeenCalledWith({
      method: "email",
      identifier: "ana@example.com",
    });
    expect(workflow.email.value).toBe("ana@example.com");
    expect(workflow.destination.value).toBe("ana@example.com");
    expect(workflow.step.value).toBe(2);

    workflow.resumeRegistration();
    workflow.name.value = "Ana Reparos";
    workflow.phone.value = "47999992222";
    workflow.accepted.value = true;
    await expect(workflow.registerProfessional()).resolves.toBe(true);
    expect(completeRegistration).toHaveBeenCalledWith({
      displayName: "Ana Reparos",
      accepted: true,
      method: "email",
      phone: "+5547999992222",
    });

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
    const workflow = scope.run(() => useProfessionalAuthFlow({ requestOtp }))!;
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

    scope.stop();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("uses the production API dependency by default and keeps transport details safe", async () => {
    const scope = effectScope();
    const workflow = scope.run(() => useProfessionalAuthFlow())!;
    workflow.phone.value = "47999991111";

    await workflow.requestCode();

    expect(workflow.error.value).toBe(
      "Não foi possível enviar o código agora. Tente novamente em instantes.",
    );

    workflow.step.value = 2;
    workflow.challengeToken.value = "browser-challenge-token";
    workflow.code.value = "123456";
    await workflow.verifyCode();
    expect(workflow.error.value).toBe(
      "Não foi possível confirmar o código agora. Tente novamente em instantes.",
    );

    workflow.name.value = "Ana Reparos";
    workflow.email.value = "ana@example.com";
    workflow.accepted.value = true;
    await expect(workflow.registerProfessional()).resolves.toBe(false);
    expect(workflow.error.value).toBe(
      "Não foi possível criar seu perfil agora. Tente novamente em instantes.",
    );
    scope.stop();
  });

  it("keeps safe registration failures on the existing final step", async () => {
    const completeRegistration = vi
      .fn()
      .mockRejectedValueOnce(
        new ApiRequestError({
          code: "validation_failed",
          message: "Revise os campos informados.",
          fieldErrors: { display_name: ["é inválido"] },
          requestId: "registration-invalid",
        }),
      )
      .mockRejectedValueOnce(new Error("private transport details"));
    const scope = effectScope();
    const workflow = scope.run(() =>
      useProfessionalAuthFlow({ completeRegistration }),
    )!;
    workflow.resumeRegistration();
    workflow.name.value = "Ana Reparos";
    workflow.email.value = "ana@example.com";
    workflow.accepted.value = true;

    await expect(workflow.registerProfessional()).resolves.toBe(false);
    expect(workflow.error.value).toBe("");
    expect(workflow.registrationFieldErrors.value).toEqual({
      display_name: ["é inválido"],
    });

    await expect(workflow.registerProfessional()).resolves.toBe(false);
    expect(workflow.error.value).toBe(
      "Não foi possível criar seu perfil agora. Tente novamente em instantes.",
    );
    scope.stop();
  });

  it("keeps provider verification failures on the existing code step", async () => {
    const requestOtp = vi.fn().mockResolvedValue({
      challengeToken: "browser-challenge-token",
      expiresIn: 600,
      resendAvailableIn: 30,
    });
    const verifyOtp = vi
      .fn()
      .mockRejectedValueOnce(
        new ApiRequestError({
          code: "invalid_otp",
          message: "Código inválido ou expirado.",
          fieldErrors: {},
          requestId: "otp-invalid",
        }),
      )
      .mockRejectedValueOnce(new Error("private transport details"));
    const scope = effectScope();
    const workflow = scope.run(() =>
      useProfessionalAuthFlow({ requestOtp, verifyOtp }),
    )!;
    workflow.phone.value = "47999991111";
    await workflow.requestCode();
    workflow.code.value = "000000";

    await workflow.verifyCode();
    expect(workflow.step.value).toBe(2);
    expect(workflow.error.value).toBe("Código inválido ou expirado.");

    await workflow.verifyCode();
    expect(workflow.error.value).toBe(
      "Não foi possível confirmar o código agora. Tente novamente em instantes.",
    );

    workflow.changeDestination();
    workflow.code.value = "123456";
    await workflow.verifyCode();
    expect(workflow.error.value).toBe("Código inválido ou expirado.");
    scope.stop();
  });
});
