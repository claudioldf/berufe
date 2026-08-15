import {
  formatBrazilianMobilePhone,
  normalizeBrazilianMobilePhone,
} from "@app/utils/brazilian-phone";

describe("Brazilian mobile phone normalization", () => {
  it.each([
    ["(47) 99999-1111", "+5547999991111"],
    ["47 99999-1111", "+5547999991111"],
    ["+55 47 99999-1111", "+5547999991111"],
  ])("normalizes %s to E.164", (input, expected) => {
    expect(normalizeBrazilianMobilePhone(input)).toBe(expected);
  });

  it.each([
    "(47) 3333-1111",
    "(10) 99999-1111",
    "47 99999-ABCD",
    "+1 202 555 0100",
  ])("rejects %s", (input) => {
    expect(normalizeBrazilianMobilePhone(input)).toBeUndefined();
  });

  it("formats normalized mobile numbers for the existing +55 confirmation copy", () => {
    expect(formatBrazilianMobilePhone("+5547999991111")).toBe(
      "(47) 99999-1111",
    );
    expect(formatBrazilianMobilePhone("invalid")).toBe("invalid");
  });
});
