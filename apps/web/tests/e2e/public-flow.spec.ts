import { expect, test } from "@playwright/test";

async function completeProfessionalSignIn(
  page: import("@playwright/test").Page,
) {
  await page.goto("/app/professional/login");
  await page.getByRole("button", { name: "Receber código" }).click();
  await page.getByLabel("Código de 6 dígitos").fill("123456");
  await page.getByRole("button", { name: "Confirmar e continuar" }).click();
  await page.getByLabel(/li e aceito/i).check();
  await page.getByRole("button", { name: "Criar meu perfil" }).click();
}

test("visitor can discover and open a professional profile", async ({
  page,
}) => {
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
  await page.getByRole("link", { name: "Ver perfil" }).first().click();
  await expect(
    page.getByRole("heading", { level: 1, name: "Marcos Alves" }),
  ).toBeVisible();
  await expect(
    page.locator('a[href^="https://wa.me/"]:visible').first(),
  ).toHaveAttribute("href", /^https:\/\/wa\.me\//);
});

test("an incomplete professional sees onboarding and can skip it", async ({
  page,
}) => {
  await completeProfessionalSignIn(page);
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
}) => {
  await completeProfessionalSignIn(page);

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

  await completeProfessionalSignIn(page);
  await expect(page).toHaveURL(/\/app\/professional$/);
});
