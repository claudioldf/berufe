import type { CurrentAccount } from "~/services/api/application-session";

export type ProfessionalAuthIntent = "login" | "signup" | "reauthentication";

export interface ProfessionalPhoneStepContent {
  eyebrow: string;
  title: string;
  description: string;
  submitLabel: string;
  alternatePrompt: string;
  alternateLabel: string;
  alternateTo: string;
  pageTitle: string;
}

export const professionalLoginPath = "/app/professional/login";
export const professionalSignupPath = `${professionalLoginPath}?intent=signup`;
export const professionalDashboardPath = "/app/professional";
export const professionalOnboardingPath = "/app/professional/onboarding";
export const professionalAccountPath = "/app/professional/account";
export const professionalReauthenticationPath = `${professionalLoginPath}?intent=reauthentication`;

type ProfessionalEntryAccount = Pick<
  CurrentAccount,
  "role" | "registrationCompleted" | "onboardingCompleted"
>;

export function resolveProfessionalEntryPath(
  account: ProfessionalEntryAccount,
) {
  if (account.role !== "professional" || !account.registrationCompleted) {
    return professionalLoginPath;
  }

  return account.onboardingCompleted
    ? professionalDashboardPath
    : professionalOnboardingPath;
}

export const professionalPhoneStepContent: Record<
  ProfessionalAuthIntent,
  ProfessionalPhoneStepContent
> = {
  login: {
    eyebrow: "Acesso profissional",
    title: "Acesse seu perfil.",
    description: "Use o celular confirmado no seu cadastro.",
    submitLabel: "Receber código para entrar",
    alternatePrompt: "Ainda não tem perfil?",
    alternateLabel: "Criar meu perfil",
    alternateTo: professionalSignupPath,
    pageTitle: "Entrar no perfil profissional",
  },
  signup: {
    eyebrow: "Cadastro profissional",
    title: "Crie seu perfil profissional.",
    description:
      "Informe seu celular para confirmar o telefone e começar. É gratuito.",
    submitLabel: "Receber código e começar",
    alternatePrompt: "Já tem perfil?",
    alternateLabel: "Entrar",
    alternateTo: professionalLoginPath,
    pageTitle: "Criar perfil profissional",
  },
  reauthentication: {
    eyebrow: "Confirmação de segurança",
    title: "Confirme seu telefone.",
    description:
      "Para excluir a conta, confirme novamente o celular vinculado ao seu perfil.",
    submitLabel: "Receber código de confirmação",
    alternatePrompt: "Não quer excluir a conta agora?",
    alternateLabel: "Voltar para a conta",
    alternateTo: professionalAccountPath,
    pageTitle: "Confirmar telefone para excluir conta",
  },
};

export function resolveProfessionalAuthIntent(
  intent: unknown,
): ProfessionalAuthIntent {
  if (intent === "signup" || intent === "reauthentication") return intent;
  return "login";
}
