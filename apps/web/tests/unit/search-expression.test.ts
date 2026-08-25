import {
  decodeSearchExpression,
  encodeSearchExpression,
} from "@app/utils/searchExpression";

describe("search expression route encoding", () => {
  it("round-trips UTF-8 through unpadded Base64URL", () => {
    const expression = "Elétrica e hidráulica no bairro América";
    const encoded = encodeSearchExpression(expression);

    expect(encoded).not.toMatch(/[+/=]/);
    expect(decodeSearchExpression(encoded)).toBe(expression);
  });

  it("rejects malformed route values", () => {
    expect(decodeSearchExpression("%%%invalid%%%")).toBe("");
    expect(decodeSearchExpression(["value"])).toBe("");
  });
});
