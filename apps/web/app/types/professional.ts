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

export interface ProfessionalPortfolioItem {
  id: string;
  title: string;
  service: string;
  description: string;
  image: string | null;
  status: "pending_review" | "approved" | "rejected" | "hidden";
  rejectionReason: string | null;
  submittedAt: string;
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
  direction: "incoming" | "outgoing";
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
  birthdate: string;
  instagram?: string;
  youtube?: string;
}

export interface PublicProfessionalCard {
  id: string;
  slug: string;
  name: string;
  headline: string | null;
  photoUrl: string | null;
  primaryService: {
    id: string;
    name: string;
    slug: string;
  } | null;
  matchingService: {
    id: string;
    name: string;
    slug: string;
  } | null;
  coverage: {
    allJoinville: boolean;
    neighborhoods: Array<{ code: string; name: string }>;
  };
  verificationLabels: Array<{
    type: "phone" | "identity";
    label: "Telefone confirmado" | "Identidade verificada";
    verifiedAt: string | null;
  }>;
  portfolioCount: number;
  relationshipCount: number;
  publicSnapshotUpdatedAt: string | null;
}

export interface PublicServiceSuggestion {
  id: string;
  name: string;
  slug: string;
  icon: string;
  description: string;
}

export interface PublicProfessionalSearchResult {
  normalizedTerm: string;
  resolvedService: PublicServiceSuggestion | null;
  neighborhood: { code: string; name: string } | null;
  professionals: PublicProfessionalCard[];
  relatedServices: PublicServiceSuggestion[];
  interaction: {
    searchEventId: string;
    token: string;
  } | null;
}

export interface PublicProfessionalProfile {
  id: string;
  slug: string;
  name: string;
  headline: string | null;
  bio: string | null;
  avatar: string | null;
  primaryService: string;
  primaryServiceSlug: string;
  services: string[];
  serviceNotes: Array<string | null>;
  neighborhoods: string[];
  allJoinville: boolean;
  yearsExperience: number | null;
  evidence: Array<
    Evidence & {
      type: "phone" | "identity";
      verifiedAt: string | null;
    }
  >;
  portfolio: Array<{
    id: string;
    title: string;
    service: string;
    description: string | null;
    image: string;
  }>;
  relationships: Array<{
    id: string;
    professionalName: string;
    professionalSlug: string;
    avatar: string | null;
    type: "recommendation" | "worked_together";
    direction: "incoming" | "outgoing";
    note: string | null;
  }>;
  updatedAt: string | null;
  instagram?: string;
  youtube?: string;
}

export interface PublicProfessionalProfileResult {
  professional: PublicProfessionalProfile;
  interactionToken: string;
}

export type ProfessionalRelationshipType = "recommendation" | "worked_together";

export interface ProfessionalRelationshipParty {
  id: string;
  publicSlug: string;
  displayName: string;
}

export interface ProfessionalRelationship {
  id: string;
  relationshipType: ProfessionalRelationshipType;
  contextNote: string | null;
  status: "pending" | "accepted" | "declined";
  createdAt: string;
  respondedAt: string | null;
  initiator: ProfessionalRelationshipParty;
  recipient: ProfessionalRelationshipParty;
}

export interface ProfessionalProfileDraft {
  name: string;
  birthdate: string;
  headline: string;
  bio: string;
  yearsExperience: number;
  whatsapp: string;
  selectedServices: string[];
  serviceNotes: Record<string, string>;
  primaryService: string;
  allJoinville: boolean;
  selectedNeighborhoods: string[];
  instagram: string;
  youtube: string;
}

export type ProfessionalProfileStatus =
  "draft" | "pending_review" | "published" | "suspended";

export type ProfessionalProfilePhotoStatus =
  "pending_review" | "approved" | "rejected" | "hidden" | "superseded";

export interface ProfessionalMediaUploadState {
  id: string;
  state:
    | "authorized"
    | "uploaded"
    | "processing"
    | "processed"
    | "failed"
    | "attached"
    | "expired";
  failureCode: string | null;
  retryable: boolean;
}

export interface ProfessionalProfilePhotoState {
  current: {
    id: string;
    status: ProfessionalProfilePhotoStatus;
    rejectionReason: string | null;
    submittedAt: string;
  } | null;
  hasPublishedPhoto: boolean;
  publishedImageUrl: string | null;
  latestUpload: ProfessionalMediaUploadState | null;
}

export interface ProfessionalVerificationState {
  current: {
    id: string;
    verificationType: "identity";
    status: "pending_review" | "approved" | "rejected" | "expired";
    rejectionReason: string | null;
    submittedAt: string;
  } | null;
}

export interface ProfessionalWorkspace {
  dashboard: {
    localDate: string;
    readiness: {
      percentage: number;
      steps: {
        identityContact: boolean;
        serviceCoverage: boolean;
        reviewablePortfolio: boolean;
        approvedIdentity: boolean;
      };
    };
    recentQuotes: Array<{
      id: string;
      number: number;
      customerName: string;
      serviceDescription: string;
      total: number;
      status: "draft" | "shared";
      createdAt: string;
    }>;
  };
  pendingRelationships: ProfessionalRelationship[];
  profile: {
    id: string;
    publicSlug: string;
    status: ProfessionalProfileStatus;
    isPublic: boolean;
    isSearchEligible: boolean;
    publicationBlockers: Array<"identity" | "photo" | "services" | "coverage">;
    revisionStatus:
      "draft" | "pending_review" | "approved" | "rejected" | "superseded";
    revisionRejectionReason: string | null;
    hasPublishedRevision: boolean;
    photo: ProfessionalProfilePhotoState;
    portfolioItems: ProfessionalPortfolioItem[];
    verification: ProfessionalVerificationState;
    identity: Pick<
      ProfessionalProfileDraft,
      | "name"
      | "birthdate"
      | "headline"
      | "bio"
      | "yearsExperience"
      | "whatsapp"
      | "instagram"
      | "youtube"
    >;
    services: Array<{
      id: string;
      name: string;
      isPrimary: boolean;
      note: string;
    }>;
    coverage: {
      allJoinville: boolean;
      neighborhoods: Array<{ code: string; name: string }>;
    };
  };
}
