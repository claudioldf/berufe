export type AdminProfessionalProfileStatus =
  "draft" | "published" | "suspended";

export type AdminProfessionalTriState = "all" | "yes" | "no";

export type AdminProfessionalSort = "recent" | "last_login_desc" | "name_asc";

export interface AdminProfessionalItem {
  id: string;
  professionalProfileId: string | null;
  publicSlug: string | null;
  displayName: string | null;
  profileStatus: AdminProfessionalProfileStatus | null;
  city: string | null;
  state: string | null;
  phoneVerified: boolean;
  phoneLast4: string | null;
  identityVerified: boolean;
  accountStatus: "active" | "suspended";
  impersonationEligible: boolean;
  portfolioCount: number;
  referenceCount: number;
  customerCount: number;
  quoteCount: number;
  registeredAt: string | null;
  lastLoginAt: string | null;
  loginCount: number;
  publishedAt: string | null;
}

export interface AdminProfessionalsSummary {
  total: number;
  published: number;
  suspended: number;
  onboardingFinished: number;
  identityVerified: number;
}

export interface AdminProfessionalPageMeta {
  page: number;
  perPage: number;
  totalCount: number;
  totalPages: number;
}

export interface AdminProfessionalPage {
  items: AdminProfessionalItem[];
  summary: AdminProfessionalsSummary;
  meta: AdminProfessionalPageMeta;
}

export interface AdminProfessionalFilters {
  page: number;
  q: string;
  phone: string;
  city: string | null;
  state: string | null;
  identityVerified: AdminProfessionalTriState;
  onboardingFinished: AdminProfessionalTriState;
  sort: AdminProfessionalSort;
}
