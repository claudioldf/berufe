import { expect, test, type Locator, type Page } from "@playwright/test";

async function waitForNuxtHydration(page: Page) {
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

async function signInExistingProfessional(page: Page, phone: string) {
  await page.goto("/app/professional/login");
  await waitForNuxtHydration(page);
  await page.getByLabel("Celular com DDD").fill(phone);
  await page.getByRole("button", { name: "Receber código" }).click();
  await page.getByLabel("Código de 6 dígitos").fill("123456");
  await page.getByRole("button", { name: "Confirmar e continuar" }).click();
  await page.waitForURL(/\/app\/professional(?:\/onboarding)?$/);
}

async function clickQuoteAction(page: Page, name: string) {
  const action = page.getByRole("button", { name });
  if ((page.viewportSize()?.width ?? 0) <= 720) {
    await action.scrollIntoViewIfNeeded();
    await action.focus();
    await page.keyboard.press("Enter");
    return;
  }
  await action.click();
}

async function expectActionAtCardBottom(card: Locator, name: string) {
  const cardBox = await card.boundingBox();
  const actionBox = await card.getByRole("button", { name }).boundingBox();

  expect(cardBox).not.toBeNull();
  expect(actionBox).not.toBeNull();
  expect(
    cardBox!.y + cardBox!.height - (actionBox!.y + actionBox!.height),
  ).toBeLessThanOrEqual(20);
}

test("professional dashboard prioritizes operational work responsively", async ({
  page,
}, testInfo) => {
  test.setTimeout(60_000);
  const professionalPhone = testInfo.project.name.startsWith("mobile")
    ? "47999990000"
    : "47999993333";
  await signInExistingProfessional(page, professionalPhone);
  await page.goto("/app/professional");
  await waitForNuxtHydration(page);

  const layout = page.locator(".dashboard-layout");
  const status = page.locator(".status-banner");
  const operational = page.locator(".dashboard-operational");
  const sidebar = page.locator(".dashboard-sidebar");
  await expect(layout).toBeVisible();
  await expect(
    operational.getByText("Transforme pedidos em trabalhos fechados."),
  ).toBeVisible();
  await expect(operational.getByText("Orçamentos recentes.")).toHaveCount(0);
  await expect(
    operational.getByText("Ferramentas", { exact: true }),
  ).toHaveCount(0);
  await expect(sidebar.getByText("Ações rápidas")).toBeVisible();

  const statusBox = await status.boundingBox();
  const operationalBox = await operational.boundingBox();
  const sidebarBox = await sidebar.boundingBox();
  expect(statusBox).not.toBeNull();
  expect(operationalBox).not.toBeNull();
  expect(sidebarBox).not.toBeNull();

  if (testInfo.project.name.startsWith("mobile")) {
    expect(operationalBox!.y).toBeGreaterThan(statusBox!.y + statusBox!.height);
    expect(sidebarBox!.y).toBeGreaterThan(
      operationalBox!.y + operationalBox!.height,
    );
    expect(Math.abs(statusBox!.x - operationalBox!.x)).toBeLessThanOrEqual(1);
    expect(
      Math.abs(statusBox!.width - operationalBox!.width),
    ).toBeLessThanOrEqual(1);
    return;
  }

  expect(operationalBox!.x).toBeGreaterThan(statusBox!.x + statusBox!.width);
  expect(Math.abs(statusBox!.x - sidebarBox!.x)).toBeLessThanOrEqual(1);
  expect(operationalBox!.width / statusBox!.width).toBeGreaterThan(1.9);
  expect(operationalBox!.width / statusBox!.width).toBeLessThan(2.1);
});

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
  await waitForNuxtHydration(page);

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

  await clickQuoteAction(page, "Pré-visualizar");
  const preview = page.getByRole("dialog", { name: "Prévia do orçamento" });
  await expect(preview.getByText(customerName)).toBeVisible();
  await page.keyboard.press("Escape");

  const createResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/v1/professional/quotes") &&
      response.request().method() === "POST",
  );
  await clickQuoteAction(page, "Salvar e compartilhar");
  expect((await createResponse).status()).toBe(201);
  await expect(page).toHaveURL(/\/quotes\/new\?quote=[a-f0-9-]+$/);
  const shareDialog = page.getByRole("dialog", {
    name: "Compartilhar orçamento",
  });
  await expect(shareDialog).toBeVisible();
  const shareResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/share") &&
      response.request().method() === "POST",
  );
  await shareDialog.getByRole("button", { name: "Copiar link" }).click();
  const sharePayload = await (await shareResponse).json();
  await expect(page).toHaveURL(/\/quotes\/new\?quote=[a-f0-9-]+$/);
  const editorUrl = page.url();
  const sharedPath = new URL(sharePayload.data.share_url).pathname;
  expect(sharedPath).toMatch(/^\/orcamento\/bq_[A-Za-z0-9_-]{43}$/);
  await expect(page.getByText("Compartilhado").first()).toBeVisible();

  const sharedResponse = await page.goto(sharedPath);
  await waitForNuxtHydration(page);
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
  await waitForNuxtHydration(page);
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
  browser,
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
  await page.goto("/app/professional");
  await page
    .locator(".actions-card")
    .getByRole("button", { name: "Recomendar um profissional" })
    .click();
  const requestDialog = page.getByRole("dialog", {
    name: "Conectar com um profissional",
  });
  await requestDialog.getByLabel("Nome do profissional").fill(recipient.name);
  const continueButton = requestDialog.getByRole("button", {
    name: "Continuar",
    exact: true,
  });
  await expect(
    requestDialog.getByRole("button", {
      name: /Não encontrei a pessoa na lista.*Continuar informando o telefone/,
    }),
  ).toBeVisible();
  await expect(continueButton).toBeDisabled();
  await requestDialog
    .getByRole("button", { name: new RegExp(recipient.name) })
    .click();
  await expect(continueButton).toBeEnabled();
  await continueButton.click();
  await requestDialog.getByLabel("Contexto").fill(note);
  const requestResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/v1/professional/relationships") &&
      response.request().method() === "POST",
  );
  await requestDialog
    .getByRole("button", { name: "Conectar", exact: true })
    .click();
  expect((await requestResponse).status()).toBe(201);
  await page.goto("/app/professional/profile?tab=relacoes");
  const outbound = page.locator(".relationship-card").filter({ hasText: note });
  await expect(outbound).toContainText("Aguardando confirmação");
  await expect(outbound).toContainText(recipient.name);
  await expectActionAtCardBottom(outbound, "Cancelar solicitação de conexão");

  await page.goto("/app/professional");
  const ongoingSection = page.locator(".activity-section--ongoing");
  await expect(ongoingSection).toContainText("Para acompanhar.");
  const outboundOverview = ongoingSection
    .locator("article")
    .filter({ hasText: recipient.name });
  await expect(outboundOverview).toContainText("Aguardando confirmação");

  const recipientContext = await browser.newContext({
    baseURL: new URL(page.url()).origin,
  });
  const recipientPage = await recipientContext.newPage();
  await signInExistingProfessional(recipientPage, recipient.phone);
  await recipientPage.goto("/app/professional");
  const attentionSection = recipientPage.locator(
    ".activity-section--attention",
  );
  await expect(attentionSection).toContainText("Para resolver.");
  const overviewPending = attentionSection
    .locator("article")
    .filter({ hasText: initiator.name });
  await expect(overviewPending).toContainText("Aguardando sua resposta");

  await recipientPage.goto("/app/professional/profile?tab=relacoes");
  const pending = recipientPage
    .locator(".relationship-card")
    .filter({ hasText: note });
  await expect(pending).toContainText("Aguardando sua resposta");
  const responseRequest = recipientPage.waitForResponse(
    (response) =>
      response.url().endsWith("/response") &&
      response.request().method() === "POST",
  );
  await pending.getByRole("button", { name: "Conectar" }).click();
  expect((await responseRequest).status()).toBe(200);

  await recipientPage.goto(`/profissionais/${recipient.slug}`);
  await expect(recipientPage.getByText(note)).toBeVisible();
  await expect(
    recipientPage.getByText(`Recomendado por ${initiator.name}`),
  ).toBeVisible();

  await page.goto("/app/professional/profile?tab=relacoes");
  const accepted = page.locator(".relationship-card").filter({ hasText: note });
  await expect(accepted).toContainText("Vocês estão conectados");
  await expectActionAtCardBottom(accepted, "Remover conexão");
  await accepted.getByRole("button", { name: "Remover conexão" }).click();
  const removeDialog = page.getByRole("dialog", { name: "Remover conexão" });
  const removeResponse = page.waitForResponse(
    (response) =>
      response.url().includes("/api/v1/professional/relationships/") &&
      response.request().method() === "DELETE",
  );
  await removeDialog.getByRole("button", { name: "Remover conexão" }).click();
  expect((await removeResponse).status()).toBe(200);
  await expect(accepted).toHaveCount(0);

  const replacementNote = `${note} novamente`;
  await page.goto("/app/professional/profile?tab=relacoes");
  await page
    .locator(".relationship-manager")
    .getByRole("button", { name: "Conectar" })
    .first()
    .click();
  const replacementDialog = page.getByRole("dialog", {
    name: "Conectar com um profissional",
  });
  await replacementDialog
    .getByLabel("Nome do profissional")
    .fill(recipient.name);
  await replacementDialog
    .getByRole("button", { name: new RegExp(recipient.name) })
    .click();
  await replacementDialog
    .getByRole("button", { name: "Continuar", exact: true })
    .click();
  await replacementDialog.getByLabel("Contexto").fill(replacementNote);
  const replacementResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/v1/professional/relationships") &&
      response.request().method() === "POST",
  );
  await replacementDialog
    .getByRole("button", { name: "Conectar", exact: true })
    .click();
  expect((await replacementResponse).status()).toBe(201);

  await recipientPage.goto(`/profissionais/${recipient.slug}`);
  await expect(recipientPage.getByText(note)).toHaveCount(0);
  await expect(recipientPage.getByText(replacementNote)).toHaveCount(0);

  await page.goto("/app/professional/profile?tab=relacoes");
  const replacement = page
    .locator(".relationship-card")
    .filter({ hasText: replacementNote });
  await replacement
    .getByRole("button", { name: "Cancelar solicitação" })
    .click();
  const cancelDialog = page.getByRole("dialog", {
    name: "Cancelar solicitação",
  });
  const cancelResponse = page.waitForResponse(
    (response) =>
      response.url().includes("/api/v1/professional/relationships/") &&
      response.request().method() === "DELETE",
  );
  await cancelDialog
    .getByRole("button", { name: "Cancelar solicitação" })
    .click();
  expect((await cancelResponse).status()).toBe(200);
  await expect(replacement).toHaveCount(0);
  await recipientContext.close();
});

test("an indicated professional claims the external profile and publishes the complete version", async ({
  browser,
  page,
  request,
}, testInfo) => {
  test.setTimeout(240_000);
  const mobile = testInfo.project.name.startsWith("mobile");
  const initiator = mobile
    ? { phone: "47999999999", name: "Patrícia Almeida" }
    : { phone: "47999997777", name: "Camila Nunes" };
  const randomSuffix = Math.floor(Math.random() * 90_000_000) + 10_000_000;
  const externalPhone = `479${randomSuffix}`;
  const externalName = `Carla Indicada ${randomSuffix.toString().slice(-4)}`;
  const note = `Indicação externa E2E ${randomSuffix}`;
  const externalService = { name: "Chaveiro", slug: "chaveiro" };

  await signInExistingProfessional(page, initiator.phone);
  await page.goto("/app/professional/profile?tab=relacoes");
  await page
    .locator(".relationship-manager")
    .getByRole("button", { name: "Conectar" })
    .first()
    .click();
  const dialog = page.getByRole("dialog", {
    name: "Conectar com um profissional",
  });
  await dialog.getByLabel("Nome do profissional").fill(externalName);
  await dialog.getByRole("button", { name: "Continuar", exact: true }).click();
  await dialog.getByLabel("Celular com DDD").fill(externalPhone);
  await dialog.getByLabel(externalService.name, { exact: true }).check();
  await dialog.getByLabel("Contexto").fill(note);
  const createResponsePromise = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/v1/professional/relationships") &&
      response.request().method() === "POST",
  );
  await dialog.getByRole("button", { name: "Conectar", exact: true }).click();
  const createResponse = await createResponsePromise;
  expect(createResponse.status()).toBe(201);
  const createPayload = await createResponse.json();
  const externalProfile = createPayload.data.relationship.recipient as {
    id: string;
    public_slug: string;
  };

  await page.goto(`/profissionais/${externalProfile.public_slug}`);
  await expect(
    page.getByRole("heading", { level: 1, name: externalName }),
  ).toBeVisible();
  await expect(page.getByText("Perfil adicionado por indicação")).toBeVisible();
  await expect(page.getByText("Joinville · área não informada")).toBeVisible();
  await expect(
    page.getByText(externalService.name, { exact: true }),
  ).toBeVisible();
  await expect(page.getByText(note)).toHaveCount(0);
  await expect(page.getByText("Frase de apresentação")).toHaveCount(0);
  await expect(page.getByText("Conte um pouco sobre seu trabalho")).toHaveCount(
    0,
  );
  expect(await page.locator("body").innerText()).not.toContain(externalPhone);

  const contact = page
    .locator('a[href*="/whatsapp?source=public_profile"]:visible')
    .first();
  const contactUrl = await contact.getAttribute("href");
  expect(contactUrl).toBeTruthy();
  expect(contactUrl).not.toContain(externalPhone);
  const redirect = await request.get(contactUrl!, { maxRedirects: 0 });
  expect(redirect.status()).toBe(302);
  expect(redirect.headers().location).toContain(externalPhone);

  await page.goto("/encontrar");
  await page
    .getByRole("searchbox", { name: "O que você precisa?" })
    .fill(externalService.name);
  await page.getByRole("button", { name: "Encontrar" }).click();
  const externalCard = page
    .locator(".professional-card")
    .filter({ hasText: externalName });
  await expect(externalCard).toContainText("Perfil por indicação", {
    timeout: 15_000,
  });

  const recipientContext = await browser.newContext({
    baseURL: new URL(page.url()).origin,
  });
  const recipientPage = await recipientContext.newPage();
  await recipientPage.goto("/app/professional/login");
  await recipientPage.getByLabel("Celular com DDD").fill(externalPhone);
  await recipientPage.getByRole("button", { name: "Receber código" }).click();
  await recipientPage.getByLabel("Código de 6 dígitos").fill("123456");
  await recipientPage
    .getByRole("button", { name: "Confirmar e continuar" })
    .click();
  await expect(recipientPage.getByLabel("Nome profissional")).toHaveValue(
    externalName,
  );
  await recipientPage.getByLabel(/li e aceito/i).check();
  await recipientPage.getByRole("button", { name: "Criar meu perfil" }).click();
  await expect(recipientPage).toHaveURL(/\/app\/professional\/onboarding$/);

  await recipientPage.goto(`/profissionais/${externalProfile.public_slug}`);
  await expect(
    recipientPage.getByText("Telefone confirmado pelo profissional"),
  ).toBeVisible();
  await expect(
    recipientPage.getByText("Perfil adicionado por indicação"),
  ).toBeVisible();

  await recipientPage.goto("/app/professional/profile?tab=relacoes");
  const pending = recipientPage
    .locator(".relationship-card")
    .filter({ hasText: note });
  await expect(pending).toContainText("Aguardando sua resposta");
  const acceptResponsePromise = recipientPage.waitForResponse(
    (response) =>
      response.url().endsWith("/response") &&
      response.request().method() === "POST",
  );
  await pending.getByRole("button", { name: "Conectar" }).click();
  expect((await acceptResponsePromise).status()).toBe(200);

  await recipientPage.goto(`/profissionais/${externalProfile.public_slug}`);
  await expect(recipientPage.getByText(note)).toBeVisible();
  await expect(
    recipientPage.getByText(`Recomendado por ${initiator.name}`),
  ).toBeVisible();

  await recipientPage.goto("/app/professional/onboarding");
  await waitForNuxtHydration(recipientPage);
  await recipientPage.getByLabel("Data de nascimento").fill("1990-04-12");
  await recipientPage
    .getByLabel("Frase de apresentação")
    .fill("Elétrica residencial com atendimento cuidadoso.");
  await recipientPage
    .getByLabel("Conte um pouco sobre seu trabalho")
    .fill("Instalações e manutenção elétrica residencial em Joinville.");
  await recipientPage
    .locator(".profile-photo-control__input")
    .setInputFiles("public/images/professional-marcos-alves-electrician.jpg");
  await expect(
    recipientPage.getByText(/Foto salva e aguardando revisão|Foto revisada/),
  ).toBeVisible({ timeout: 30_000 });
  await recipientPage
    .getByRole("button", { name: "Salvar e continuar" })
    .click();
  await expect(
    recipientPage.getByRole("heading", {
      name: "Escolha o que você oferece.",
    }),
  ).toBeVisible();
  await recipientPage.getByLabel("Estado").selectOption("42");
  await recipientPage.getByLabel("Cidade").selectOption("4209102");
  await recipientPage.getByLabel("Atendo em toda Joinville").check();
  await recipientPage
    .getByRole("button", { name: "Salvar e continuar" })
    .click();
  const publishResponsePromise = recipientPage.waitForResponse(
    (response) =>
      response.url().endsWith("/api/v1/professional/profile/submission") &&
      response.request().method() === "POST",
  );
  await recipientPage
    .getByRole("button", {
      name: "Pular verificação e publicar perfil",
    })
    .click();
  expect((await publishResponsePromise).status()).toBe(200);
  await expect(
    recipientPage.getByRole("heading", {
      name: "Seu perfil já pode ser encontrado.",
    }),
  ).toBeVisible();

  await recipientPage.goto(`/profissionais/${externalProfile.public_slug}`);
  await expect(
    recipientPage.getByRole("heading", { level: 1, name: externalName }),
  ).toBeVisible();
  await expect(
    recipientPage.getByText("Perfil adicionado por indicação"),
  ).toHaveCount(0);
  await expect(
    recipientPage.getByText("Elétrica residencial com atendimento cuidadoso."),
  ).toBeVisible();
  await expect(recipientPage.getByText(note)).toBeVisible();
  await recipientContext.close();
});
