import {
  formatBrazilianMobilePhone,
  maskBrazilianMobilePhone,
  normalizeBrazilianMobilePhone,
  sanitizeBrazilianMobilePhone,
} from "@app/utils/brazilian-phone";

describe("Brazilian mobile phone normalization", () => {
  it.each([
    ["(47) 9 9999-1111", "+5547999991111"],
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

  it("formats mobile numbers with a separated ninth digit", () => {
    expect(formatBrazilianMobilePhone("+5547999991111")).toBe(
      "(47) 9 9999-1111",
    );
    expect(formatBrazilianMobilePhone("invalid")).toBe("invalid");
  });

  it("applies the mask progressively and limits input to one mobile number", () => {
    expect(maskBrazilianMobilePhone("4")).toBe("(4");
    expect(maskBrazilianMobilePhone("479")).toBe("(47) 9");
    expect(maskBrazilianMobilePhone("47999991111")).toBe("(47) 9 9999-1111");
    expect(maskBrazilianMobilePhone("47999991111999")).toBe("(47) 9 9999-1111");
  });

  it("sanitizes formatted phones to digits before API requests", () => {
    expect(sanitizeBrazilianMobilePhone("(47) 9 9999-1111")).toBe(
      "5547999991111",
    );
    expect(sanitizeBrazilianMobilePhone("+55 (47) 9 9999-1111")).toBe(
      "5547999991111",
    );
  });
});
