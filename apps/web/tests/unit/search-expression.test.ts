import {
  decodeSearchExpression,
  encodeSearchExpression,
  readEncodedSearchExpression,
  searchExpressionQuery,
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

  it("builds canonical q state and still reads the legacy parameter", () => {
    const encoded = encodeSearchExpression("Eletricista");

    expect(searchExpressionQuery(encoded)).toEqual({ q: encoded });
    expect(readEncodedSearchExpression({ q: encoded })).toBe(encoded);
    expect(readEncodedSearchExpression({ expressao: encoded })).toBe(encoded);
    expect(
      readEncodedSearchExpression({ q: encoded, expressao: "legado" }),
    ).toBe(encoded);
  });
});
