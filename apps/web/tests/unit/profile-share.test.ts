import { useShare } from "@app/composables/useShare";

const mocks = vi.hoisted(() => ({ showToast: vi.fn() }));

vi.mock("@app/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
}));

function setNavigatorShare(
  value: ((data: ShareData) => Promise<void>) | undefined,
) {
  Object.defineProperty(navigator, "share", {
    configurable: true,
    value,
  });
}

describe("profile sharing", () => {
  const writeText = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    writeText.mockResolvedValue(undefined);
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText },
    });
    setNavigatorShare(undefined);
  });

  it("copies the stable public URL when the Web Share API is unavailable", async () => {
    const { share } = useShare();

    await expect(
      share({
        title: "Ana Souza na Berufe",
        text: "Conheça meu trabalho na Berufe.",
        url: "https://berufe.com.br/profissionais/ana-souza",
      }),
    ).resolves.toBe(true);

    expect(writeText).toHaveBeenCalledWith(
      "https://berufe.com.br/profissionais/ana-souza",
    );
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({ title: "Link copiado" }),
    );
  });

  it("uses the device share sheet without copying when it succeeds", async () => {
    const nativeShare = vi.fn().mockResolvedValue(undefined);
    setNavigatorShare(nativeShare);
    const options = {
      title: "Ana Souza na Berufe",
      text: "Conheça meu trabalho na Berufe.",
      url: "https://berufe.com.br/profissionais/ana-souza",
    };

    await expect(useShare().share(options)).resolves.toBe(true);

    expect(nativeShare).toHaveBeenCalledWith(options);
    expect(writeText).not.toHaveBeenCalled();
  });
});
