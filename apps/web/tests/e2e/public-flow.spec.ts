import { expect, test } from "@playwright/test";

async function completeProfessionalSignIn(
  page: import("@playwright/test").Page,
  phone: string,
) {
  await page.goto("/app/professional/login");
  await page.getByLabel("Celular com DDD").fill(phone);
  await page.getByRole("button", { name: "Receber código" }).click();
  await page.getByLabel("Código de 6 dígitos").fill("123456");
  await page.getByRole("button", { name: "Confirmar e continuar" }).click();
  await page.getByLabel("Nome profissional").fill("Marcos Alves");
  await page.getByLabel(/li e aceito/i).check();
  await page.getByRole("button", { name: "Criar meu perfil" }).click();
}

function syntheticPhone(projectName: string, sequence: number) {
  const projectDigit = projectName.startsWith("mobile") ? "2" : "1";
  return `479${projectDigit}111${sequence.toString().padStart(4, "0")}`;
}

test("visitor can search, open a profile, and inspect the WhatsApp redirect", async ({
  page,
  request,
}) => {
  const browserErrors: string[] = [];
  page.on("console", (message) => {
    if (message.type() === "error") browserErrors.push(message.text());
  });
  page.on("pageerror", (error) => browserErrors.push(error.message));

  await page.goto("/");
  await expect(
    page.getByRole("heading", { level: 1, name: /sua casa em boas mãos/i }),
  ).toBeVisible();

  await page.goto("/encontrar?servico=eletricista&bairro=america");
  await expect(
    page.getByText(
      /\d+ (?:profissional encontrado|profissionais encontrados)/i,
    ),
  ).toBeVisible();
  const profileResponsePromise = page.waitForResponse(
    (response) =>
      response.url().includes("/api/v1/public/professionals/") &&
      !response.url().includes("/views") &&
      response.request().method() === "GET",
  );
  const profileViewResponsePromise = page.waitForResponse(
    (response) =>
      response.url().endsWith("/views") &&
      response.request().method() === "POST",
  );
  await page.getByRole("link", { name: "Ver perfil" }).first().click();
  await expect((await profileResponsePromise).status()).toBe(200);
  await expect((await profileViewResponsePromise).status()).toBe(204);
  await expect(
    page.getByRole("heading", { level: 1, name: "Marcos Alves" }),
  ).toBeVisible();
  const contact = page
    .locator('a[href*="/whatsapp?source=public_profile"]:visible')
    .first();
  const contactUrl = await contact.getAttribute("href");
  expect(contactUrl).toBeTruthy();
  expect(contactUrl).not.toContain("wa.me");
  expect(contactUrl).not.toMatch(/5547\d{9}/);

  const redirect = await request.get(contactUrl!, {
    maxRedirects: 0,
    headers: {
      "User-Agent": "Mozilla/5.0 AppleWebKit/537.36 Chrome/140 Safari/537.36",
    },
  });
  expect(redirect.status()).toBe(302);
  expect(redirect.headers().location).toMatch(
    /^https:\/\/wa\.me\/\d{12,13}\?text=/,
  );
  expect(decodeURIComponent(redirect.headers().location)).toContain("Berufe");
  expect(browserErrors).toEqual([]);
});

test("an incomplete professional sees onboarding and can skip it", async ({
  page,
}, testInfo) => {
  await completeProfessionalSignIn(
    page,
    syntheticPhone(testInfo.project.name, 1),
  );
  await expect(page).toHaveURL(/\/app\/professional\/onboarding$/);
  await expect(
    page.getByRole("heading", { level: 1, name: /deixar seu perfil pronto/i }),
  ).toBeVisible();
  await expect(
    page.getByRole("progressbar", { name: "Progresso do perfil" }),
  ).toHaveAttribute("aria-valuenow", "0");

  await page.getByRole("link", { name: "Pular por agora" }).click();
  await expect(page).toHaveURL(/\/app\/professional$/);
  await expect(page.getByRole("heading", { level: 1 })).toContainText("Marcos");
});

test("professional can reach 100% and retain frontend progress", async ({
  page,
}, testInfo) => {
  await completeProfessionalSignIn(
    page,
    syntheticPhone(testInfo.project.name, 2),
  );

  await page
    .getByLabel("Frase de apresentação")
    .fill("Elétrica residencial com cuidado e clareza.");
  await page
    .getByLabel("Conte um pouco sobre seu trabalho")
    .fill("Trabalho com instalações e manutenção elétrica residencial.");
  await page.getByRole("button", { name: "Salvar e continuar" }).click();

  await expect(
    page.getByRole("heading", { name: "Escolha o que você oferece." }),
  ).toBeVisible();
  await page.getByRole("button", { name: /Eletricista/ }).click();
  await page.getByLabel("Atendo em toda Joinville").check();
  await page.getByRole("button", { name: "Salvar e continuar" }).click();

  await expect(
    page.getByRole("heading", { name: "Mostre um trabalho bem feito." }),
  ).toBeVisible();
  await page.locator('input[name="portfolio-image"]').setInputFiles({
    name: "cozinha.jpg",
    mimeType: "image/jpeg",
    buffer: Buffer.from("portfolio-mock"),
  });
  await page.getByLabel("Título do trabalho").fill("Iluminação da cozinha");
  await page.getByRole("button", { name: "Salvar e continuar" }).click();

  await expect(
    page.getByRole("heading", { name: "Finalize com sua identidade." }),
  ).toBeVisible();
  await page.locator('input[name="identity-document"]').setInputFiles({
    name: "documento.png",
    mimeType: "image/png",
    buffer: Buffer.from("identity-mock"),
  });
  await page.getByRole("button", { name: "Enviar e concluir" }).click();

  await expect(page.getByText("Perfil 100% completo")).toBeVisible();
  await expect(
    page.getByRole("heading", {
      name: "Você concluiu os primeiros passos.",
    }),
  ).toBeVisible();

  await page.reload();
  await expect(page.getByText("Perfil 100% completo")).toBeVisible();

  await completeProfessionalSignIn(
    page,
    syntheticPhone(testInfo.project.name, 3),
  );
  await expect(page).toHaveURL(/\/app\/professional$/);
});
