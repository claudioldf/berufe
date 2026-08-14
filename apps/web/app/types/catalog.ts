export type CatalogTab = "services" | "neighborhoods";

export interface CatalogCategoryOption {
  id: string;
  name: string;
}

export interface CatalogEntry {
  id: string;
  name: string;
  identifier: string;
  description: string;
  category?: string;
  stateCode?: string;
  city?: string;
  active: boolean;
}

export interface CatalogEntryDraft {
  name: string;
  identifier: string;
  description: string;
  category?: string;
  stateCode?: string;
  city?: string;
}
