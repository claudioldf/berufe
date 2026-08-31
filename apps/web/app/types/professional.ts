import type {
  ProfessionalServiceJob,
  RecommendationDeliveryChannel,
} from "./service-job";
import type { LocationCoverage } from "./location";
import type { SearchLocation } from "./ui";

export interface Service {
  id: string;
  name: string;
  slug: string;
  category: string;
  icon: string;
  description: string;
  aliases: string[];
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
  submittedAt: string;
}

export interface PortfolioItemDraft {
  file: File;
  title: string;
  service: string;
  description: string;
}

export interface PortfolioItemUpdateDraft {
  file: File | null;
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
  coverage: LocationCoverage;
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
  profileType: "self_service" | "external";
  claimed: boolean;
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
    city: LocationCoverage["city"];
    wholeCity: boolean;
    neighborhoods: LocationCoverage["neighborhoods"];
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
  professionals: PublicProfessionalCard[];
  relatedServices: PublicServiceSuggestion[];
  page: number;
  perPage: number;
  totalCount: number;
  totalPages: number;
  interpretation: {
    services: PublicServiceSuggestion[];
    effectiveLocation: SearchLocation;
    locations: Array<{
      cityCode: string;
      stateCode: string;
      city: string;
      neighborhood: { code: string; name: string } | null;
    }>;
    normalizedRequest: string | null;
  };
  interaction: {
    searchEventId: string;
    token: string;
  } | null;
}

export interface PublicProfessionalListing {
  service: PublicServiceSuggestion;
  location: SearchLocation;
  professionals: PublicProfessionalCard[];
  relatedServices: PublicServiceSuggestion[];
  page: number;
  perPage: number;
  totalCount: number;
  totalPages: number;
  indexable: boolean;
}

export interface PublicServiceCoverageEntry {
  service: PublicServiceSuggestion;
  location: SearchLocation;
  professionalCount: number;
  indexable: boolean;
}

export interface PublicServiceDemand {
  released: boolean;
  searches: number | null;
}

export interface PublicProfessionalProfile {
  id: string;
  slug: string;
  profileType: "self_service" | "external";
  claimed: boolean;
  name: string;
  headline: string | null;
  bio: string | null;
  avatar: string | null;
  primaryService: string | null;
  primaryServiceSlug: string | null;
  primaryServiceIcon: string | null;
  services: string[];
  serviceNotes: Array<string | null>;
  coverage: LocationCoverage;
  yearsExperience: number | null;
  evidence: Array<
    Evidence & {
      type: "phone" | "identity";
      verifiedAt: string | null;
    }
  >;
  evidenceSummary: {
    registeredServices: number;
    recommendations: number;
    hiddenRecommendations: number;
    workedTogetherProfessionals: number;
  };
  customerRecommendations: Array<{
    id: string;
    displayName: string;
    text: string;
    submittedAt: string;
    verificationLabel: "Link enviado por e-mail" | "Link enviado por WhatsApp";
  }>;
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
  indexable: boolean;
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
  profileType: "self_service" | "external";
  photoUrl: string | null;
  profileAvailable: boolean;
}

export interface ProfessionalRelationship {
  id: string;
  relationshipType: ProfessionalRelationshipType;
  contextNote: string | null;
  status: "pending" | "accepted" | "declined";
  source: "existing_profile" | "external_phone";
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
  coverageCityCode: string;
  coversWholeCity: boolean;
  selectedNeighborhoodCodes: string[];
  instagram: string;
  youtube: string;
}

export type ProfessionalProfileStatus = "draft" | "published" | "suspended";

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
    submittedAt: string;
  } | null;
  hasPhoto: boolean;
  imageUrl: string | null;
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

export type ProfessionalActionKind =
  | "quote_unshared"
  | "quote_awaiting_response"
  | "quote_change_requested"
  | "service_open"
  | "recommendation_unsent";

export interface ProfessionalActionItem {
  id: string;
  kind: ProfessionalActionKind;
  title: string;
  subtitle: string;
  sortAt: string;
  recommendationDeliveryChannel: RecommendationDeliveryChannel | null;
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
    actionItems: ProfessionalActionItem[];
    recentQuotes: Array<{
      id: string;
      number: number;
      revision: number;
      customerName: string;
      serviceDescription: string;
      total: number;
      status:
        | "draft"
        | "saved"
        | "shared"
        | "change_requested"
        | "approved"
        | "declined";
      serviceJobStatus: ProfessionalServiceJob["status"] | null;
      createdAt: string;
    }>;
    recentServiceJobs: ProfessionalServiceJob[];
  };
  pendingRelationships: ProfessionalRelationship[];
  relationships: ProfessionalRelationship[];
  profile: {
    id: string;
    publicSlug: string;
    status: ProfessionalProfileStatus;
    presentationType: "self_service" | "external";
    isPublic: boolean;
    isSearchEligible: boolean;
    isIndexable: boolean;
    suspensionReason: string | null;
    publicationBlockers: Array<"identity" | "photo" | "services" | "coverage">;
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
      city: LocationCoverage["city"];
      wholeCity: boolean;
      neighborhoods: LocationCoverage["neighborhoods"];
    };
  };
}
