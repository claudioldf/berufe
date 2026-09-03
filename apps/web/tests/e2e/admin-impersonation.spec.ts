import { expect, test } from "@playwright/test";

async function waitForNuxtHydration(page: import("@playwright/test").Page) {
  await page.waitForFunction(() =>
    Boolean(
      (
        document.querySelector("#__nuxt") as Element & {
          __vue_app__?: unknown;
        }
      )?.__vue_app__,
    ),
  );
}

test("administrator manages a professional account and returns to the directory", async ({
  page,
}, testInfo) => {
  test.skip(
    testInfo.project.name !== "chromium",
    "The delegated-session behavior does not vary by viewport.",
  );

  await page.goto("/app/admin/login");
  await waitForNuxtHydration(page);
  await page.locator("#admin-email").fill("admin@berufe.com.br");
  await page.locator("#admin-password").fill("@Qwer1234");
  await page.getByRole("button", { name: "Entrar" }).click();
  await expect(page).toHaveURL(/\/app\/admin$/);

  await page.goto("/app/admin/professionals?q=Marcos%20Alves");
  const professionalRow = page
    .getByRole("row")
    .filter({ hasText: "Marcos Alves" });
  await expect(professionalRow).toBeVisible();
  await professionalRow
    .getByRole("button", { name: "Gerenciar conta" })
    .click();

  await expect(page).toHaveURL(/\/app\/professional$/);
  const banner = page.getByText(
    "Você está gerenciando a conta de Marcos Alves",
  );
  await expect(banner).toBeVisible();
  await expect(page.getByRole("button", { name: "Sair" })).toBeHidden();

  await page.goto("/app/admin/professionals");
  await expect(page).toHaveURL(/\/app\/professional$/);
  await page.goto("/app/professional/account/exclusion");
  await expect(page).toHaveURL(/\/app\/professional$/);

  await page.getByRole("button", { name: "Voltar ao admin" }).click();
  await expect(page).toHaveURL(
    /\/app\/admin\/professionals\?q=Marcos(?:%20|\+)Alves$/,
  );
  await expect(
    page.getByRole("heading", { name: "Profissionais", exact: true }),
  ).toBeVisible();
  await expect(banner).toBeHidden();
  await expect(page.getByRole("button", { name: "Sair" })).toBeVisible();
});
