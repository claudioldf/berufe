export type ReportPeriodKey = "since_launch" | "last_30_days" | "last_7_days";

export interface ReportPeriodOption {
  key: ReportPeriodKey;
  label: string;
  shortLabel: string;
}

export interface ReportRate {
  numerator: number;
  denominator: number;
  rate: number | null;
}

export interface ReportCountStage {
  key: string;
  label: string;
  value: number;
  description?: string;
  rate?: number | null;
}

export interface ReportRatioMetric {
  key: string;
  label: string;
  value: number;
  total: number;
  rate: number | null;
  description: string;
  icon: string;
}

export interface ReportPeriodData {
  generatedAt: string;
  period: ReportPeriodOption & { windowLabel: string; truncated: boolean };
  privacyNotice: string;
  summary: {
    published: { value: number; currentStock: number; change: string };
    activated: ReportRate & { change: string };
    searchCoverage: ReportRate & { change: string };
    handoffs: ReportRate & { change: string };
    returning: ReportRate & { change: string };
  };
  supply: {
    targetMinimum: number;
    targetMaximum: number;
    funnel: ReportCountStage[];
    activation: ReportRatioMetric[];
  };
  discovery: {
    stages: Array<ReportRate & { key: string; label: string }>;
    profileViews: number;
    whatsappHandoffs: number;
    demand: Array<{ label: string; value: number }>;
    gaps: Array<{
      service: string;
      location: string;
      searches: number;
      professionals: number;
      catalogStatus: "active" | "inactive" | "outside_mvp";
    }>;
  };
  engagement: {
    eligibleProfessionals: number;
    meaningfulActives: number;
    returningProfessionals: number;
    activeWeeks: ReportCountStage[];
    actions: ReportCountStage[];
    cohorts: Array<{
      cohort: string;
      size: number;
      week1: number | null;
      week4: number | null;
    }>;
  };
  trust: {
    funnels: Array<{
      key: "relationships";
      label: string;
      started: number;
      responded: number;
      approved: number;
      responseRate: ReportRate;
      approvalRate: ReportRate;
    }>;
  };
  quotes: {
    created: number;
    shared: number;
    shareRate: ReportRate;
    uniqueCreators: number;
    repeatCreators: number;
  };
  operations: {
    pending: number;
    oldestPendingHours: number;
    oldestPendingTargetHours: number;
    medianReviewHours: number;
    p90ReviewHours: number;
    rejected: number;
    reviewed: number;
    approvalRate: ReportRate;
    hidden: number;
    restored: number;
  };
}
