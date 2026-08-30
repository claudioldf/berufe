const validAreaCodes = new Set([
  "11",
  "12",
  "13",
  "14",
  "15",
  "16",
  "17",
  "18",
  "19",
  "21",
  "22",
  "24",
  "27",
  "28",
  "31",
  "32",
  "33",
  "34",
  "35",
  "37",
  "38",
  "41",
  "42",
  "43",
  "44",
  "45",
  "46",
  "47",
  "48",
  "49",
  "51",
  "53",
  "54",
  "55",
  "61",
  "62",
  "63",
  "64",
  "65",
  "66",
  "67",
  "68",
  "69",
  "71",
  "73",
  "74",
  "75",
  "77",
  "79",
  "81",
  "82",
  "83",
  "84",
  "85",
  "86",
  "87",
  "88",
  "89",
  "91",
  "92",
  "93",
  "94",
  "95",
  "96",
  "97",
  "98",
  "99",
]);

export function normalizeBrazilianMobilePhone(
  input: string,
): string | undefined {
  let digits = input
    .trim()
    .replace(/^\+/, "")
    .replace(/[\s().-]/g, "");
  if (digits.length === 13 && digits.startsWith("55")) {
    digits = digits.slice(2);
  }

  if (
    !/^\d{2}9\d{8}$/.test(digits) ||
    !validAreaCodes.has(digits.slice(0, 2))
  ) {
    return undefined;
  }

  return `+55${digits}`;
}

export function brazilianMobilePhoneDigits(input: string): string {
  let digits = input.replace(/\D/g, "");
  if (digits.length > 11 && digits.startsWith("55")) digits = digits.slice(2);
  return digits.slice(0, 11);
}

export function maskBrazilianMobilePhone(input: string): string {
  const digits = brazilianMobilePhoneDigits(input);
  if (!digits) return "";
  if (digits.length <= 2) return `(${digits}`;

  const areaCode = digits.slice(0, 2);
  const ninthDigit = digits.slice(2, 3);
  const firstBlock = digits.slice(3, 7);
  const lastBlock = digits.slice(7, 11);
  let masked = `(${areaCode}) ${ninthDigit}`;
  if (firstBlock) masked += ` ${firstBlock}`;
  if (lastBlock) masked += `-${lastBlock}`;
  return masked;
}

export function sanitizeBrazilianMobilePhone(input: string): string {
  const normalized = normalizeBrazilianMobilePhone(input);
  return normalized ? normalized.replace(/\D/g, "") : input.replace(/\D/g, "");
}

export function formatBrazilianMobilePhone(phone: string): string {
  return normalizeBrazilianMobilePhone(phone)
    ? maskBrazilianMobilePhone(phone)
    : phone;
}
