import { matchSearchAction, searchActions } from "~/utils/search-actions";

describe("matchSearchAction", () => {
  it.each([
    ["Excluir perfil", "excluir-conta"],
    ["excluir conta", "excluir-conta"],
    ["APAGAR CONTA", "excluir-conta"],
    ["remover conta", "excluir-conta"],
    ["cadastrar", "criar-conta"],
    ["cancelar cadastro", "excluir-conta"],
    ["cadastro", "criar-conta"],
    ["Criar conta", "criar-conta"],
    ["login", "entrar"],
    ["acessar conta", "entrar"],
    ["editar perfil", "editar-perfil"],
    ["atualizar perfil", "editar-perfil"],
  ])("maps %j to %s", (expression, slug) => {
    expect(matchSearchAction(expression)?.slug).toBe(slug);
  });

  it("ignores accents, punctuation and surrounding spaces", () => {
    expect(matchSearchAction("  Excluír   conta!! ")?.slug).toBe(
      "excluir-conta",
    );
    expect(matchSearchAction("anunciar meus serviços")?.slug).toBe(
      "criar-conta",
    );
  });

  it("looks through wrapper words like 'como' and 'minha'", () => {
    expect(matchSearchAction("como excluir minha conta")?.slug).toBe(
      "excluir-conta",
    );
    expect(matchSearchAction("quero me cadastrar")?.slug).toBe("criar-conta");
    expect(matchSearchAction("como fazer login")?.slug).toBe("entrar");
  });

  it("prefers a literal alias over wrapper-stripping", () => {
    expect(matchSearchAction("minha conta")?.slug).toBe("entrar");
  });

  it.each([
    "eletricista",
    "excluir entulho",
    "cadastro de móveis",
    "pintor em joinville",
    "criar conta de luz",
    "editar vídeo",
    "conta",
    "",
  ])("leaves the service search alone for %j", (expression) => {
    expect(matchSearchAction(expression)).toBeUndefined();
  });

  it("returns nothing for a missing expression", () => {
    expect(matchSearchAction(undefined)).toBeUndefined();
  });

  it("points every action at a help page and a workspace page", () => {
    for (const action of searchActions) {
      expect(action.helpPath).toBe(`/ajuda/${action.slug}`);
      expect(action.appPath).toMatch(/^\/app\/professional/);
    }
  });
});
