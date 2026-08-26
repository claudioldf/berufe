import type {
  SearchAuditItem,
  SearchAuditOutcome,
  SearchAuditStatus,
} from "~/types";

export const searchAuditOutcomeLabels: Record<SearchAuditOutcome, string> = {
  zero_results: "Sem resultados",
  not_understood: "Não compreendida",
  thin_results: "Poucos resultados",
  operational_issue: "Falha operacional",
  healthy: "Saudável",
};

export const searchAuditStatusLabels: Record<SearchAuditStatus, string> = {
  processing: "Processando",
  completed: "Concluída",
  application_rate_limited: "Limite da aplicação",
  provider_rate_limited: "Limite do provedor",
  provider_unavailable: "Provedor indisponível",
  response_rejected: "Resposta rejeitada",
  search_failed: "Busca indisponível",
};

const operationalStatuses = new Set<SearchAuditStatus>([
  "processing",
  "application_rate_limited",
  "provider_rate_limited",
  "provider_unavailable",
  "search_failed",
]);

export function searchAuditOutcome(item: SearchAuditItem): SearchAuditOutcome {
  if (item.status === "completed" && item.resultCount === 0) {
    return "zero_results";
  }
  if (item.status === "response_rejected") return "not_understood";
  if (
    item.status === "completed" &&
    item.resultCount >= 1 &&
    item.resultCount <= 2
  ) {
    return "thin_results";
  }
  if (operationalStatuses.has(item.status)) return "operational_issue";
  return "healthy";
}

export function searchAuditServiceLabel(item: SearchAuditItem) {
  const services = item.parsedResponse?.services.map((service) => service.name);
  return services?.length ? services.join(", ") : "Não identificado";
}

export function searchAuditLocationLabel(item: SearchAuditItem) {
  const locations = item.parsedResponse?.locations.map((location) => {
    const neighborhood = location.neighborhood
      ? `${location.neighborhood.name}, `
      : "";
    return `${neighborhood}${location.city} - ${location.stateCode}`;
  });
  return locations?.length ? [...new Set(locations)].join(" · ") : "—";
}

export function searchAuditCityLabel(item: SearchAuditItem) {
  const locations = item.parsedResponse?.locations.map(
    (location) => `${location.city} - ${location.stateCode}`,
  );
  return locations?.length ? [...new Set(locations)].join(" · ") : "—";
}

export function searchAuditRawResponseLabel(item: SearchAuditItem) {
  if (item.rawLlmResponse) return item.rawLlmResponse;
  if (item.status === "application_rate_limited") {
    return "Rejeitada antes do envio ao LLM.";
  }
  return "Nenhuma resposta bruta foi recebida.";
}

export function searchAuditParsedResponseLabel(item: SearchAuditItem) {
  return item.parsedResponse
    ? JSON.stringify(item.parsedResponse, null, 2)
    : "Nenhuma resposta interpretada.";
}
