export interface LocationState {
  code: string;
  abbreviation: string;
  name: string;
}

export interface LocationCity {
  code: string;
  name: string;
  slug: string;
  stateCode: string;
  stateAbbreviation: string;
  stateName: string;
}

export interface Neighborhood {
  code: string;
  cityCode: string;
  name: string;
}

export interface LocationCoverage {
  city: LocationCity | null;
  wholeCity: boolean;
  neighborhoods: Array<Pick<Neighborhood, "code" | "name">>;
}

export interface LocationCoverageDraft {
  cityCode: string;
  wholeCity: boolean;
  neighborhoodCodes: string[];
}
