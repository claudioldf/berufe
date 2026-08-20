import { expect, test, type Page } from "@playwright/test";

async function signInExistingProfessional(page: Page, phone: string) {
  await page.goto("/app/professional/login");
  await page.getByLabel("Celular com DDD").fill(phone);
  await page.getByRole("button", { name: "Receber código" }).click();
  await page.getByLabel("Código de 6 dígitos").fill("123456");
  await page.getByRole("button", { name: "Confirmar e continuar" }).click();
  await page.waitForURL(/\/app\/professional(?:\/onboarding)?$/);
}

async function signOut(page: Page) {
  await page.goto("/app/professional");
  if ((page.viewportSize()?.width ?? 0) <= 720) {
    await page.getByRole("button", { name: "Abrir menu" }).click();
  }
  await page.getByRole("button", { name: "Sair" }).click();
  await page.waitForURL(/\/app\/professional\/login$/);
}

async function clickQuoteAction(page: Page, name: string) {
  if ((page.viewportSize()?.width ?? 0) <= 720) {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  }
  await page.getByRole("button", { name }).click();
}

test("published professional creates, previews, securely shares, and live-edits a quote", async ({
  context,
  page,
}, testInfo) => {
  test.setTimeout(90_000);
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  const professionalPhone = testInfo.project.name.startsWith("mobile")
    ? "47999992222"
    : "47999991111";
  await signInExistingProfessional(page, professionalPhone);
  await page.goto("/app/professional/quotes/new");

  const projectLabel = testInfo.project.name.startsWith("mobile")
    ? "Mobile"
    : "Desktop";
  const customerName = `Cliente E2E ${projectLabel}`;
  await page.getByLabel("Nome do cliente").fill(customerName);
  await page
    .getByLabel("Descrição do serviço")
    .fill("Adequação elétrica da cozinha");
  await page.getByLabel("Descrição do item 1").fill("Instalação elétrica");
  await page.getByLabel("Quantidade do item 1").fill("2");
  await page.getByLabel("Valor unitário do item 1").fill("125.50");

  const createResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/v1/professional/quotes") &&
      response.request().method() === "POST",
  );
  await clickQuoteAction(page, "Salvar rascunho");
  expect((await createResponse).status()).toBe(201);
  await expect(page).toHaveURL(/\/quotes\/new\?quote=[a-f0-9-]+$/);
  const editorUrl = page.url();
  await expect(
    page.locator(".quote-builder__savebar").getByText("Rascunho salvo"),
  ).toBeVisible();

  await clickQuoteAction(page, "Pré-visualizar");
  const preview = page.getByRole("dialog", { name: "Prévia do orçamento" });
  await expect(preview.getByText(customerName)).toBeVisible();
  await page.keyboard.press("Escape");

  await clickQuoteAction(page, "Compartilhar");
  const shareDialog = page.getByRole("dialog", {
    name: "Compartilhar orçamento",
  });
  const shareResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/share") &&
      response.request().method() === "POST",
  );
  await shareDialog.getByRole("button", { name: "Copiar link" }).click();
  const sharePayload = await (await shareResponse).json();
  const sharedPath = new URL(sharePayload.data.share_url).pathname;
  expect(sharedPath).toMatch(/^\/orcamento\/bq_[A-Za-z0-9_-]{43}$/);
  await expect(page.getByText("Compartilhado").first()).toBeVisible();

  const sharedResponse = await page.goto(sharedPath);
  expect(sharedResponse?.status()).toBe(200);
  expect(sharedResponse?.headers()["cache-control"]).toBe("private, no-store");
  expect(sharedResponse?.headers()["referrer-policy"]).toBe("no-referrer");
  expect(sharedResponse?.headers()["x-robots-tag"]).toBe("noindex, nofollow");
  await expect(
    page.getByRole("heading", { name: "Aqui está seu orçamento." }),
  ).toBeVisible();
  await expect(page.getByText(customerName, { exact: true })).toBeVisible();
  await page.evaluate(() => {
    window.print = () =>
      document.body.setAttribute("data-print-called", "true");
  });
  await page.getByRole("button", { name: "Imprimir" }).click();
  await expect(page.locator("body")).toHaveAttribute(
    "data-print-called",
    "true",
  );

  const invalidResponse = await page.goto("/orcamento/malformed");
  expect(invalidResponse?.status()).toBe(404);
  await expect(
    page.getByRole("heading", { name: "Orçamento não encontrado" }),
  ).toBeVisible();

  await page.goto(editorUrl);
  const updatedCustomerName = `${customerName} atualizado`;
  await page.getByLabel("Nome do cliente").fill(updatedCustomerName);
  const updateResponse = page.waitForResponse(
    (response) =>
      response.url().includes("/api/v1/professional/quotes/") &&
      response.request().method() === "PATCH",
  );
  await clickQuoteAction(page, "Salvar rascunho");
  expect((await updateResponse).status()).toBe(200);
  await page.goto(sharedPath);
  await expect(
    page.getByText(updatedCustomerName, { exact: true }),
  ).toBeVisible();
});

test("existing members publish a relationship by confirming it together", async ({
  page,
}, testInfo) => {
  test.setTimeout(90_000);
  const mobile = testInfo.project.name.startsWith("mobile");
  const initiator = mobile
    ? { phone: "47999996666", name: "Diego Fernandes" }
    : { phone: "47999994444", name: "Carlos Henrique Lima" };
  const recipient = mobile
    ? { phone: "47999998888", name: "Eduardo Rocha", slug: "eduardo-rocha" }
    : {
        phone: "47999995555",
        name: "Rafael Oliveira",
        slug: "rafael-oliveira",
      };
  const note = `Relação E2E ${testInfo.project.name}`;

  await signInExistingProfessional(page, initiator.phone);
  await page.goto(`/profissionais/${recipient.slug}`);
  await page
    .getByRole("button", { name: "Solicitar relação profissional" })
    .click();
  const requestDialog = page.getByRole("dialog", {
    name: "Solicitar relação profissional",
  });
  await requestDialog.getByLabel("Contexto").fill(note);
  const requestResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/v1/professional/relationships") &&
      response.request().method() === "POST",
  );
  await requestDialog
    .getByRole("button", { name: "Enviar solicitação" })
    .click();
  expect((await requestResponse).status()).toBe(201);
  await signOut(page);

  await signInExistingProfessional(page, recipient.phone);
  await page.goto("/app/professional");
  const pending = page
    .locator(".pending-list article")
    .filter({ hasText: initiator.name });
  const responseRequest = page.waitForResponse(
    (response) =>
      response.url().endsWith("/response") &&
      response.request().method() === "POST",
  );
  await pending.getByRole("button", { name: "Confirmar" }).click();
  expect((await responseRequest).status()).toBe(200);
  await signOut(page);

  await page.goto(`/profissionais/${recipient.slug}`);
  await expect(page.getByText(note)).toBeVisible();
  await expect(
    page.getByText(`Recomendado por ${initiator.name}`),
  ).toBeVisible();
});
