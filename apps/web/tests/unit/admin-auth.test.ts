import { mount } from "@vue/test-utils";
import AdminLoginForm from "~/components/auth/AdminLoginForm.vue";
import { useAdminAuthFlow } from "~/composables/useAdminAuthFlow";
import { createAdminSession } from "~/services/api/admin-session";
import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";

function apiClientReturning(result: object) {
  return {
    POST: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("administrator session API", () => {
  it("creates a session through the dedicated generated operation", async () => {
    const client = apiClientReturning({
      data: {
        data: { status: "authenticated" },
        request_id: "admin-login-success",
      },
      error: undefined,
      response: new Response(null, { status: 200 }),
    });

    await expect(
      createAdminSession(client, {
        email: "admin@example.com",
        password: "a-secure-admin-password",
      }),
    ).resolves.toBeUndefined();
    expect(client.POST).toHaveBeenCalledWith("/api/v1/admin/session", {
      body: {
        email: "admin@example.com",
        password: "a-secure-admin-password",
      },
    });
  });

  it("normalizes contracted and malformed failures", async () => {
    const invalid = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "invalid_credentials",
          message: "E-mail ou senha inválidos.",
          request_id: "admin-login-invalid",
        },
      },
      response: new Response(null, {
        status: 401,
        headers: { "X-Request-Id": "admin-login-invalid" },
      }),
    });

    await expect(
      createAdminSession(invalid, {
        email: "admin@example.com",
        password: "incorrect-password",
      }),
    ).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "invalid_credentials",
      requestId: "admin-login-invalid",
    });

    const malformed = apiClientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null, { status: 503 }),
    });
    await expect(
      createAdminSession(malformed, {
        email: "admin@example.com",
        password: "a-secure-admin-password",
      }),
    ).rejects.toMatchObject({ code: "unexpected_error", requestId: "client" });
  });
});

describe("administrator authentication flow", () => {
  it("validates required credentials before calling the API", async () => {
    const authenticate = vi.fn();
    const workflow = useAdminAuthFlow({ authenticate });

    await expect(workflow.login()).resolves.toBe(false);
    expect(workflow.error.value).toBe("Informe seu e-mail e sua senha.");
    expect(authenticate).not.toHaveBeenCalled();
  });

  it("submits normalized input once and clears the password after success", async () => {
    let resolveAuthentication: (() => void) | undefined;
    const authenticate = vi.fn(
      () =>
        new Promise<void>((resolve) => {
          resolveAuthentication = resolve;
        }),
    );
    const workflow = useAdminAuthFlow({ authenticate });
    workflow.email.value = " admin@example.com ";
    workflow.password.value = "a-secure-admin-password";

    const authentication = workflow.login();
    await expect(workflow.login()).resolves.toBe(false);
    expect(workflow.isLoading.value).toBe(true);
    expect(authenticate).toHaveBeenCalledOnce();
    expect(authenticate).toHaveBeenCalledWith({
      email: "admin@example.com",
      password: "a-secure-admin-password",
    });

    resolveAuthentication?.();
    await expect(authentication).resolves.toBe(true);
    expect(workflow.password.value).toBe("");
    expect(workflow.isLoading.value).toBe(false);
  });

  it("surfaces safe API and unexpected failures", async () => {
    const apiError = new ApiRequestError({
      code: "invalid_credentials",
      message: "E-mail ou senha inválidos.",
      fieldErrors: {},
      requestId: "admin-login-invalid",
    });
    const authenticate = vi
      .fn()
      .mockRejectedValueOnce(apiError)
      .mockRejectedValueOnce(new Error("database password is secret"));
    const workflow = useAdminAuthFlow({ authenticate });
    workflow.email.value = "admin@example.com";
    workflow.password.value = "incorrect-password";

    await expect(workflow.login()).resolves.toBe(false);
    expect(workflow.error.value).toBe("E-mail ou senha inválidos.");

    await expect(workflow.login()).resolves.toBe(false);
    expect(workflow.error.value).toBe(
      "Não foi possível entrar agora. Tente novamente em instantes.",
    );
    expect(workflow.error.value).not.toContain("database password");
  });

  it("uses the configured API client by default and keeps setup failures safe", async () => {
    const workflow = useAdminAuthFlow();
    workflow.email.value = "admin@example.com";
    workflow.password.value = "a-secure-admin-password";

    await expect(workflow.login()).resolves.toBe(false);
    expect(workflow.error.value).toBe(
      "Não foi possível entrar agora. Tente novamente em instantes.",
    );
  });
});

describe("administrator login form", () => {
  it("submits only the approved email and password fields with accessible errors", async () => {
    const wrapper = mount(AdminLoginForm, {
      props: {
        email: "",
        password: "",
        loading: false,
        error: "",
      },
      global: {
        stubs: {
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          UButton: {
            props: ["loading"],
            template: '<button :data-loading="loading"><slot /></button>',
          },
          UIcon: true,
        },
      },
    });

    expect(wrapper.findAll("input")).toHaveLength(2);
    expect(wrapper.get("#admin-email").attributes("autocomplete")).toBe(
      "username",
    );
    expect(wrapper.get("#admin-password").attributes("autocomplete")).toBe(
      "current-password",
    );
    await wrapper.get("#admin-email").setValue("admin@example.com");
    await wrapper.get("#admin-password").setValue("a-secure-admin-password");
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("update:email")?.at(-1)).toEqual([
      "admin@example.com",
    ]);
    expect(wrapper.emitted("update:password")?.at(-1)).toEqual([
      "a-secure-admin-password",
    ]);
    expect(wrapper.emitted("submit")).toHaveLength(1);

    await wrapper.setProps({
      loading: true,
      error: "E-mail ou senha inválidos.",
    });
    expect(wrapper.get("button").attributes("data-loading")).toBe("true");
    expect(wrapper.get('[role="alert"]').text()).toContain(
      "E-mail ou senha inválidos.",
    );
    expect(wrapper.get("#admin-email").attributes("aria-invalid")).toBe("true");
  });
});
