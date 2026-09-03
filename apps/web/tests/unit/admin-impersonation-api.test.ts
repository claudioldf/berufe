import type { BerufeApiClient } from "@app/services/api/client";
import {
  startAdminProfessionalImpersonation,
  stopAdminProfessionalImpersonation,
} from "@app/services/api/admin-impersonation";

const currentSession = {
  account: {
    id: "5f6a2c1a-1111-4c00-9000-000000000001",
    role: "professional" as const,
    status: "active" as const,
    registered: true,
    verified: true,
    registration_completed: true,
    onboarding_completed: true,
    registration_display_name: "Ana Souza",
    professional_profile_id: "5f6a2c1a-2222-4c00-9000-000000000002",
    relationship_eligible: false,
  },
  session: {
    authentication_method: "password" as const,
    impersonating: true,
    authenticated_at: "2026-09-02T12:00:00Z",
    idle_expires_at: "2026-09-02T12:30:00Z",
    absolute_expires_at: "2026-09-03T00:00:00Z",
  },
};

describe("administrator impersonation API", () => {
  it("starts and maps the effective professional session", async () => {
    const client = {
      POST: vi.fn().mockResolvedValue({
        data: { data: currentSession, request_id: "impersonation-start" },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    const restored = await startAdminProfessionalImpersonation(
      client,
      currentSession.account.id,
    );

    expect(client.POST).toHaveBeenCalledWith("/api/v1/admin/impersonation", {
      body: { professional_account_id: currentSession.account.id },
    });
    expect(restored.account.registrationDisplayName).toBe("Ana Souza");
    expect(restored.session).toMatchObject({
      authenticationMethod: "password",
      impersonating: true,
    });
  });

  it("stops and maps the restored administrator session", async () => {
    const adminSession = {
      ...currentSession,
      account: {
        ...currentSession.account,
        id: "5f6a2c1a-3333-4c00-9000-000000000003",
        role: "admin" as const,
        registered: false,
        verified: false,
        registration_completed: false,
        onboarding_completed: false,
        registration_display_name: null,
        professional_profile_id: null,
      },
      session: { ...currentSession.session, impersonating: false },
    };
    const client = {
      DELETE: vi.fn().mockResolvedValue({
        data: { data: adminSession, request_id: "impersonation-stop" },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    const restored = await stopAdminProfessionalImpersonation(client);

    expect(client.DELETE).toHaveBeenCalledWith("/api/v1/admin/impersonation");
    expect(restored.account.role).toBe("admin");
    expect(restored.session.impersonating).toBe(false);
  });

  it("normalizes API failures", async () => {
    const client = {
      POST: vi.fn().mockResolvedValue({
        data: undefined,
        error: {
          error: {
            code: "impersonation_unavailable",
            message: "Não é possível gerenciar esta conta profissional.",
            request_id: "impersonation-failed",
          },
        },
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    await expect(
      startAdminProfessionalImpersonation(client, currentSession.account.id),
    ).rejects.toThrow("Não é possível gerenciar esta conta profissional.");
  });
});
