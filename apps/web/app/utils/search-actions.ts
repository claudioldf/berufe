import { normalizeSearchText } from "~/utils/text";

export type SearchActionSlug =
  "entrar" | "criar-conta" | "excluir-conta" | "editar-perfil";

export interface SearchAction {
  slug: SearchActionSlug;
  /** Where a signed-in professional is sent. */
  appPath: string;
  /** Help page for everyone else. */
  helpPath: string;
  aliases: readonly string[];
}

export const searchActions: readonly SearchAction[] = [
  {
    slug: "entrar",
    appPath: "/app/professional",
    helpPath: "/ajuda/entrar",
    aliases: [
      "entrar",
      "login",
      "logar",
      "acessar",
      "acessar conta",
      "fazer login",
      "minha conta",
    ],
  },
  {
    slug: "criar-conta",
    appPath: "/app/professional",
    helpPath: "/ajuda/criar-conta",
    aliases: [
      "cadastro",
      "cadastrar",
      "criar conta",
      "criar perfil",
      "me cadastrar",
      "cadastro profissional",
      "anunciar meus servicos",
    ],
  },
  {
    slug: "excluir-conta",
    appPath: "/app/professional/account/exclusion",
    helpPath: "/ajuda/excluir-conta",
    aliases: [
      "excluir conta",
      "excluir perfil",
      "excluir cadastro",
      "apagar conta",
      "apagar perfil",
      "deletar conta",
      "cancelar conta",
      "cancelar cadastro",
      "remover conta",
      "remover perfil",
    ],
  },
  {
    slug: "editar-perfil",
    appPath: "/app/professional/profile",
    helpPath: "/ajuda/editar-perfil",
    aliases: [
      "editar perfil",
      "alterar perfil",
      "alterar dados",
      "atualizar perfil",
      "mudar foto",
    ],
  },
];

// Words that only wrap the request ("como excluir minha conta"). They are
// dropped for a second matching attempt, never used to match on their own.
const fillerWords = new Set([
  "como",
  "quero",
  "eu",
  "preciso",
  "gostaria",
  "de",
  "da",
  "do",
  "minha",
  "meu",
  "a",
  "o",
  "um",
  "uma",
]);

const actionByAlias = new Map<string, SearchAction>(
  searchActions.flatMap((action) =>
    action.aliases.map(
      (alias) => [normalizeSearchText(alias), action] as const,
    ),
  ),
);

/**
 * Returns the account action a search expression asks for, or `undefined`.
 * Matching is exact on the whole phrase: "excluir entulho" or "cadastro de
 * móveis" keep going to the service search.
 */
export function matchSearchAction(
  expression: string | undefined,
): SearchAction | undefined {
  const normalized = normalizeSearchText(expression);
  if (!normalized) return undefined;

  const direct = actionByAlias.get(normalized);
  if (direct) return direct;

  const withoutFillers = normalized
    .split(" ")
    .filter((word) => !fillerWords.has(word))
    .join(" ");
  return withoutFillers ? actionByAlias.get(withoutFillers) : undefined;
}
