import type { ProfessionalProfileDraft } from "@app/types/professional";

export type OnboardingStepId = "profile" | "services" | "verification";

export interface OnboardingStepDefinition {
  id: OnboardingStepId;
  label: string;
  description: string;
  icon: string;
}

export interface OnboardingChecklistItem {
  id: OnboardingStepId | "portfolio";
  label: string;
  description: string;
  icon: string;
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
  verification: string | null;
}

export interface ProfessionalOnboardingState {
  version: 2;
  initialized: boolean;
  profile: ProfessionalProfileDraft;
  photoReady: boolean;
  verificationStatus: "not_started" | "submitted" | "skipped";
  completion: OnboardingCompletionState;
}

export interface OnboardingProfileErrors {
  name: string;
  birthdate: string;
  photo: string;
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
