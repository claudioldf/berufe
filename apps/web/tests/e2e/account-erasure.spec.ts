import { expect, test } from "@playwright/test";

test.setTimeout(60_000);

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

const runPhoneSegment = (Math.floor(Math.random() * 90) + 10).toString();

function syntheticPhone(projectName: string, scenarioDigit: string) {
  const projectDigit = projectName.startsWith("mobile") ? "4" : "3";
  return "479" + projectDigit + scenarioDigit + runPhoneSegment + "9025";
}

async function registerProfessional(
  page: import("@playwright/test").Page,
  projectName: string,
  scenarioDigit: string,
) {
  const phone = syntheticPhone(projectName, scenarioDigit);
  const displayName = `Conta LGPD ${projectName} ${scenarioDigit}${runPhoneSegment}`;
  await page.goto("/app/professional/login?intent=signup");
  await waitForNuxtHydration(page);
  await page.getByLabel("Celular com DDD").fill(phone);
  await page.getByRole("button", { name: "Receber código e começar" }).click();
  await page.getByLabel("Código de 6 dígitos").fill("123456");
  await page.getByRole("button", { name: "Confirmar e continuar" }).click();
  await page.getByLabel("Nome profissional").fill(displayName);
  await page.getByLabel(/li e aceito/i).check();
  await page.getByRole("button", { name: "Criar meu perfil" }).click();
  await expect(page).toHaveURL(/\/app\/professional\/onboarding$/);
  return phone;
}

test("professional can irreversibly erase the account and follow a privacy-safe status", async ({
  page,
}, testInfo) => {
  const phone = await registerProfessional(page, testInfo.project.name, "1");

  await page.goto("/app/professional/profile");
  await page.getByRole("link", { name: "Excluir minha conta" }).click();
  await expect(page).toHaveURL(/\/app\/professional\/account$/);
  await expect(
    page.getByRole("heading", { name: "Excluir minha conta" }),
  ).toBeVisible();
  await expect(page.getByText("Esta ação é irreversível")).toBeVisible();
  await expect(
    page.getByText(/apagado dos nossos sistemas em até 30 dias/),
  ).toBeVisible();
  await expect(page.getByText(/permanecem por cinco anos/)).toBeVisible();

  const deleteButton = page.getByRole("button", {
    name: "Excluir conta irreversivelmente",
  });
  await expect(deleteButton).toBeDisabled();
  await page
    .getByLabel(/Entendo que a conta não poderá ser recuperada/)
    .check();
  await expect(deleteButton).toBeEnabled();

  const submissionResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/v1/professional/data-erasure-request") &&
      response.request().method() === "POST",
  );
  await deleteButton.click();
  expect((await submissionResponse).status()).toBe(202);

  await expect(page).toHaveURL(/\/exclusao-de-conta\/be_[A-Za-z0-9_-]{43}$/);
  await expect(
    page.getByRole("heading", {
      name: /Solicitação recebida|Exclusão em processamento|Exclusão concluída/,
    }),
  ).toBeVisible();
  await expect(page.getByText("Protocolo de privacidade")).toBeVisible();
  expect(
    (await page.locator("body").innerText()).replace(/\D/g, ""),
  ).not.toContain(phone);

  await page.goto("/app/professional");
  await expect(page).toHaveURL(/\/app\/professional\/login$/);
});

test("account deletion is reachable from the profile page, not the main navigation", async ({
  page,
}, testInfo) => {
  await registerProfessional(page, testInfo.project.name, "2");

  await page.goto("/app/professional/profile");
  await expect(
    page.getByRole("navigation").getByText("Conta"),
  ).not.toBeVisible();
  await expect(
    page.getByRole("link", { name: "Excluir minha conta" }),
  ).toBeVisible();
});
