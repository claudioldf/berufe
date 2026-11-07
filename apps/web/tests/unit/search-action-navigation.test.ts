import { useSearchActionNavigation } from "~/composables/useSearchActionNavigation";

function navigation(signedIn: boolean) {
  const isProfessionalSignedIn = vi.fn().mockResolvedValue(signedIn);
  return {
    isProfessionalSignedIn,
    ...useSearchActionNavigation({ isProfessionalSignedIn }),
  };
}

describe("useSearchActionNavigation", () => {
  it("sends a signed-in professional to the workspace page", async () => {
    const { resolveSearchAction } = navigation(true);

    expect(await resolveSearchAction("excluir conta")).toBe(
      "/app/professional/account/exclusion",
    );
    expect(await resolveSearchAction("editar perfil")).toBe(
      "/app/professional/profile",
    );
  });

  it("sends everyone else to the help page", async () => {
    const { resolveSearchAction } = navigation(false);

    expect(await resolveSearchAction("excluir conta")).toBe(
      "/ajuda/excluir-conta",
    );
    expect(await resolveSearchAction("cadastro")).toBe("/ajuda/criar-conta");
  });

  it("does not touch the session for an ordinary service search", async () => {
    const { resolveSearchAction, isProfessionalSignedIn } = navigation(true);

    expect(await resolveSearchAction("eletricista")).toBeNull();
    expect(isProfessionalSignedIn).not.toHaveBeenCalled();
  });
});
