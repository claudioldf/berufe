import { describe, expect, it } from "vitest";
import {
  formatCurrency,
  formatDate,
  formatPercent,
  formatRate,
  formatRateWidth,
  formatTimestampDate,
} from "~/utils/formatters";

describe("formatters", () => {
  it("formats BRL values for Brazilian readers", () => {
    expect(formatCurrency(1234.5).replace(/\s/g, " ")).toBe("R$ 1.234,50");
  });

  it("keeps percentage denominators explicit", () => {
    expect(formatPercent(1, 3)).toBe("33,3%");
    expect(formatPercent(0, 0)).toBe("—");
    expect(formatRate(1 / 3)).toBe("33,3%");
    expect(formatRate(null)).toBe("—");
  });

  it("formats rates as safe locale-independent CSS widths", () => {
    expect(formatRateWidth(null)).toBe("0%");
    expect(formatRateWidth(2 / 3)).toBe("66.67%");
    expect(formatRateWidth(-0.5)).toBe("0%");
    expect(formatRateWidth(1.5)).toBe("100%");
  });

  it("formats date-only values without local timezone drift", () => {
    expect(formatDate("2026-08-14")).toBe("14/08/2026");
    expect(formatDate()).toBe("—");
  });

  it("formats timestamp values as a São Paulo calendar date", () => {
    expect(formatTimestampDate("2026-09-02T03:00:17Z")).toBe("02/09/2026");
    // 02:00 UTC is still 23:00 the previous day in America/Sao_Paulo (UTC-3).
    expect(formatTimestampDate("2026-09-02T02:00:00Z")).toBe("01/09/2026");
    expect(formatTimestampDate()).toBe("—");
  });
});
