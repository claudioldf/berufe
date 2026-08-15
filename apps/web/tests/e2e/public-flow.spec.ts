import { expect, test } from "@playwright/test";

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

test("professional can complete the prototype sign-in flow", async ({
  page,
}) => {
  await page.goto("/entrar");
  await page.getByRole("button", { name: "Receber código" }).click();
  await page.getByLabel("Código de 6 dígitos").fill("123456");
  await page.getByRole("button", { name: "Confirmar e continuar" }).click();
  await page.getByLabel(/li e aceito/i).check();
  await page.getByRole("button", { name: "Criar meu perfil" }).click();
  await expect(page).toHaveURL(/\/painel$/);
  await expect(page.getByRole("heading", { level: 1 })).toContainText("Marcos");
});
