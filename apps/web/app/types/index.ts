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

export interface QuoteItem {
  id: number;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
}

export interface Quote {
  number: number;
  customerName: string;
  serviceDescription: string;
  validUntil: string;
  issuedAt?: string;
  discount: number;
  notes: string;
  items: QuoteItem[];
}

export interface ToastMessage {
  title: string;
  description: string;
}

export interface LegalDocumentSection {
  id: string;
  label: string;
}

export type ReportPeriodKey = "since_launch" | "last_30_days" | "last_7_days";

export interface ReportPeriodOption {
  key: ReportPeriodKey;
  label: string;
  shortLabel: string;
}

export interface ReportCountStage {
  key: string;
  label: string;
  value: number;
  description?: string;
}

export interface ReportRatioMetric {
  key: string;
  label: string;
  value: number;
  total: number;
  description: string;
  icon: string;
}

export interface ReportDemandItem {
  label: string;
  value: number;
}

export interface ReportGapItem {
  service: string;
  location: string;
  searches: number;
  professionals: number;
  catalogStatus: "active" | "outside_mvp";
}

export interface ReportRetentionCohort {
  cohort: string;
  size: number;
  week1: number | null;
  week4: number | null;
}

export interface ReportTrustFunnel {
  key: "relationships";
  label: string;
  started: number;
  completed: number;
  approved: number;
}

export interface ReportPeriodData {
  windowLabel: string;
  summaryChanges: {
    published: string;
    activated: string;
    searchCoverage: string;
    handoffs: string;
    returning: string;
  };
  supply: {
    targetMinimum: number;
    targetMaximum: number;
    funnel: ReportCountStage[];
    activation: ReportRatioMetric[];
  };
  discovery: {
    searches: number;
    searchesWithResults: number;
    searchesWithThreeResults: number;
    searchesWithProfileOpen: number;
    profileViews: number;
    whatsappHandoffs: number;
    demand: ReportDemandItem[];
    gaps: ReportGapItem[];
  };
  engagement: {
    eligibleProfessionals: number;
    meaningfulActives: number;
    returningProfessionals: number;
    activeWeeks: ReportCountStage[];
    actions: ReportCountStage[];
    cohorts: ReportRetentionCohort[];
  };
  trust: {
    funnels: ReportTrustFunnel[];
  };
  quotes: {
    created: number;
    shared: number;
    uniqueCreators: number;
    repeatCreators: number;
  };
  operations: {
    pending: number;
    oldestPendingHours: number;
    medianReviewHours: number;
    p90ReviewHours: number;
    rejected: number;
    reviewed: number;
    hidden: number;
  };
}

export interface GrowthReportsData {
  generatedAt: string;
  privacyNotice: string;
  periods: ReportPeriodOption[];
  data: Record<ReportPeriodKey, ReportPeriodData>;
}
