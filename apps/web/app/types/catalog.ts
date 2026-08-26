import type { Neighborhood, Service } from "./professional";
import type { SearchLocation } from "./ui";

export type CatalogTab = "services" | "neighborhoods";

export interface CatalogCategoryOption {
  id: string;
  name: string;
}

export interface PublicServiceCategory extends CatalogCategoryOption {
  icon: string;
}

export interface PublicCatalog {
  categories: PublicServiceCategory[];
  services: Service[];
  neighborhoods: Neighborhood[];
  cities: SearchLocation[];
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

export interface AdminCatalog {
  categories: CatalogCategoryOption[];
  services: CatalogEntry[];
  neighborhoods: CatalogEntry[];
}
