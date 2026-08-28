import type { CurrentAccount } from "~/services/api/application-session";

export type ProfessionalAuthIntent = "login" | "signup";

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
};

export function resolveProfessionalAuthIntent(
  intent: unknown,
): ProfessionalAuthIntent {
  return intent === "signup" ? "signup" : "login";
}
