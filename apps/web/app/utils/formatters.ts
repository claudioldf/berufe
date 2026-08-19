const currencyFormatter = new Intl.NumberFormat("pt-BR", {
  style: "currency",
  currency: "BRL",
});

export function formatCurrency(value: number) {
  return currencyFormatter.format(value);
}

export function formatPercent(
  value: number,
  total: number,
  maximumFractionDigits = 1,
) {
  if (!total) return "—";
  return `${new Intl.NumberFormat("pt-BR", { maximumFractionDigits }).format((value / total) * 100)}%`;
}

export function formatRate(rate: number | null, maximumFractionDigits = 1) {
  if (rate === null) return "—";
  return `${new Intl.NumberFormat("pt-BR", { maximumFractionDigits }).format(rate * 100)}%`;
}

export function formatRateWidth(rate: number | null) {
  if (rate === null) return "0%";
  const clampedRate = Math.min(Math.max(rate, 0), 1);
  const percentage = Math.round(clampedRate * 10_000) / 100;
  return `${percentage}%`;
}

export function formatDate(value?: string) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("pt-BR", { timeZone: "UTC" }).format(
    new Date(`${value}T12:00:00Z`),
  );
}

export function formatDateTime(value: string) {
  return new Intl.DateTimeFormat("pt-BR", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
    timeZone: "America/Sao_Paulo",
  }).format(new Date(value));
}
