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

  await page.goto("/app/professional/account");
  await expect(
    page.getByRole("heading", { name: "Excluir minha conta" }),
  ).toBeVisible();
  await expect(page.getByText("Esta ação é irreversível")).toBeVisible();
  await expect(page.getByText(/excluídos em até 30 dias/)).toBeVisible();
  await expect(page.getByText(/permanecem por cinco anos/)).toBeVisible();
  await expect(
    page.getByText("Telefone confirmado recentemente"),
  ).toBeVisible();

  const deleteButton = page.getByRole("button", {
    name: "Excluir conta irreversivelmente",
  });
  await expect(deleteButton).toBeDisabled();
  await page
    .getByLabel(/Entendo que a conta não poderá ser recuperada/)
    .check();
  await page.getByLabel("Digite EXCLUIR para confirmar").fill("EXCLUIR");
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

test("stale professional session is routed to SMS reauthentication", async ({
  page,
}, testInfo) => {
  test.skip(
    testInfo.project.name.startsWith("mobile"),
    "The complete deletion scenario already covers the mobile account UI.",
  );
  await registerProfessional(page, testInfo.project.name, "2");

  await page.clock.setFixedTime(new Date(Date.now() + 31 * 60 * 1_000));
  await page.goto("/app/professional/account");
  await expect(
    page.getByText("Confirmação recente por SMS necessária"),
  ).toBeVisible();
  await page.getByRole("button", { name: "Confirmar por SMS" }).click();

  await expect(page).toHaveURL(
    /\/app\/professional\/login\?intent=reauthentication$/,
  );
  await expect(
    page.getByRole("heading", { name: "Confirme seu telefone." }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Receber código de confirmação" }),
  ).toBeVisible();
});
