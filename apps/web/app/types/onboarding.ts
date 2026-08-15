import type { ProfessionalProfileDraft } from "@app/types/professional";

export type OnboardingStepId =
  "profile" | "services" | "portfolio" | "verification";

export interface OnboardingStepDefinition {
  id: OnboardingStepId;
  label: string;
  description: string;
  icon: string;
}

export interface OnboardingChecklistItem extends OnboardingStepDefinition {
  done: boolean;
  to: string;
}

export interface OnboardingPortfolioItem {
  title: string;
  service: string;
  description: string;
  submittedAt: string;
}

export interface OnboardingCompletionState {
  profile: string | null;
  services: string | null;
  portfolio: string | null;
  verification: string | null;
}

export interface ProfessionalOnboardingState {
  version: 1;
  initialized: boolean;
  profile: ProfessionalProfileDraft;
  portfolio: OnboardingPortfolioItem | null;
  verificationStatus: "not_started" | "submitted";
  completion: OnboardingCompletionState;
}

export interface OnboardingProfileErrors {
  name: string;
  whatsapp: string;
  headline: string;
  bio: string;
}

export interface OnboardingServicesErrors {
  services: string;
  coverage: string;
}

export interface OnboardingPortfolioSubmission {
  file: File;
  title: string;
  service: string;
  description: string;
}

export interface OnboardingFileValidation {
  valid: boolean;
  error: string;
}
