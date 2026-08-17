export interface Service {
  id: string;
  name: string;
  slug: string;
  category: string;
  icon: string;
  description: string;
  aliases: string[];
}

export interface Neighborhood {
  code: string;
  name: string;
  stateCode: string;
  city: string;
}

export interface Evidence {
  id: string;
  label: string;
}

export interface PortfolioItem {
  id: string;
  title: string;
  service: string;
  description: string;
  image: string;
}

export interface PortfolioItemDraft {
  file: File;
  title: string;
  service: string;
  description: string;
}

export interface VerificationSubmission {
  file: File;
  kind: "identity";
}

export interface Relationship {
  id: string;
  professionalName: string;
  professionalSlug: string;
  avatar: string;
  type: "recommendation" | "worked_together";
  note: string;
}

export interface Professional {
  id: string;
  slug: string;
  name: string;
  headline: string;
  bio: string;
  avatar: string;
  primaryService: string;
  primaryServiceSlug: string;
  services: string[];
  serviceNotes: string[];
  neighborhoods: string[];
  allJoinville: boolean;
  yearsExperience: number;
  evidence: Evidence[];
  portfolio: PortfolioItem[];
  relationships: Relationship[];
  updatedAt: string;
  whatsapp: string;
  instagram?: string;
  youtube?: string;
}

export interface ProfessionalProfileDraft {
  name: string;
  headline: string;
  bio: string;
  yearsExperience: number;
  whatsapp: string;
  selectedServices: string[];
  primaryService: string;
  allJoinville: boolean;
  selectedNeighborhoods: string[];
  instagram: string;
  youtube: string;
}

export type ProfessionalProfileStatus =
  "draft" | "pending_review" | "published" | "suspended";

export interface ProfessionalWorkspace {
  profile: {
    id: string;
    status: ProfessionalProfileStatus;
    identity: Pick<
      ProfessionalProfileDraft,
      | "name"
      | "headline"
      | "bio"
      | "yearsExperience"
      | "whatsapp"
      | "instagram"
      | "youtube"
    >;
  };
}
