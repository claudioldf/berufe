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

async function fillExpressionSearch(
  page: import("@playwright/test").Page,
  expression: string,
) {
  const input = page.getByRole("searchbox", { name: "O que você precisa?" });
  const submit = page.getByRole("button", { name: "Encontrar" });

  await expect(async () => {
    await input.fill(expression);
    await expect(submit).toBeEnabled({ timeout: 1_000 });
  }).toPass({ timeout: 10_000 });
}

async function selectLaunchCityFromModal(
  page: import("@playwright/test").Page,
) {
  await page.getByRole("button", { name: "alterar cidade" }).click();

  const dialog = page.getByRole("dialog", { name: "Escolha sua cidade" });
  await expect(dialog).toBeVisible();
  await expect(
    dialog.getByText("Mostramos apenas cidades com profissionais disponíveis."),
  ).toBeVisible();
  await expect(dialog.locator("select")).toHaveCount(0);
  await dialog.getByRole("button", { name: /Joinville\s+SC/i }).click();
  await expect(dialog).toBeHidden();
}

async function completeProfessionalSignIn(
  page: import("@playwright/test").Page,
  phone: string,
) {
  await page.goto("/app/professional/login");
  await waitForNuxtHydration(page);
  await page.getByLabel("Celular com DDD").fill(phone);
  await page.getByRole("button", { name: "Receber código" }).click();
  await page.getByLabel("Código de 6 dígitos").fill("123456");
  await page.getByRole("button", { name: "Confirmar e continuar" }).click();
  const registrationName = page.getByLabel("Nome profissional");
  const nextStep = await Promise.race([
    registrationName.waitFor({ state: "visible" }).then(() => "registration"),
    page
      .waitForURL(/\/app\/professional(?:\/onboarding)?$/)
      .then(() => "workspace"),
  ]);
  if (nextStep === "workspace") return;

  await registrationName.fill("Marcos Alves");
  await page.getByLabel(/li e aceito/i).check();
  await page.getByRole("button", { name: "Criar meu perfil" }).click();
}

const runPhoneSegment = (Math.floor(Math.random() * 900) + 100).toString();

function syntheticPhone(projectName: string, sequence: number) {
  const projectDigit = projectName.startsWith("mobile") ? "2" : "1";
  return `479${projectDigit}${runPhoneSegment}${sequence.toString().padStart(4, "0")}`;
}

test("public header makes login and professional signup easy to find", async ({
  page,
}) => {
  await page.goto("/");
  await waitForNuxtHydration(page);

  const isMobile = (page.viewportSize()?.width ?? 0) <= 900;
  const loginAction = isMobile
    ? page.locator(".header__mobile-login")
    : page.locator(".header__desktop-auth").getByRole("link", {
        name: "Entrar",
        exact: true,
      });
  const signupAction = isMobile
    ? page.locator(".header__mobile-signup-button")
    : page.locator(".header__desktop-auth").getByRole("link", {
        name: "Criar meu perfil",
        exact: true,
      });

  await expect(loginAction).toBeVisible();
  await expect(loginAction).toHaveAttribute("href", "/app/professional/login");
  await expect(signupAction).toBeVisible();
  await expect(signupAction).toHaveAttribute(
    "href",
    "/app/professional/login?intent=signup",
  );

  await signupAction.click();
  await expect(page).toHaveURL(/\/app\/professional\/login\?intent=signup$/);
  await expect(
    page.getByRole("heading", {
      level: 1,
      name: "Crie seu perfil profissional.",
    }),
  ).toBeVisible();
  await expect(
    page.getByRole("link", { name: "Entrar", exact: true }),
  ).toHaveAttribute("href", "/app/professional/login");
});

test("visitor can choose the launch city from the home and finder pages", async ({
  page,
}) => {
  await page.goto("/");
  await waitForNuxtHydration(page);
  await selectLaunchCityFromModal(page);

  await page.goto("/encontrar");
  await waitForNuxtHydration(page);
  await expect(page).toHaveURL(/\/encontrar\/sc\/joinville$/);
  await selectLaunchCityFromModal(page);
});

test("an explicit search city overrides the selected finder city", async ({
  page,
}) => {
  const searchRequests: import("@playwright/test").Request[] = [];
  page.on("request", (request) => {
    if (
      request.url().includes("/api/v1/public/professional-searches") &&
      request.method() === "POST"
    ) {
      searchRequests.push(request);
    }
  });
  await page.goto("/encontrar/sc/joinville");
  await waitForNuxtHydration(page);
  await page.evaluate(() => {
    const state = window as typeof window & {
      __finderHeadingHistory?: string[];
    };
    const headings: string[] = [];
    const recordHeading = () => {
      const heading = document
        .querySelector(".finder__masthead h1")
        ?.textContent?.replace(/\s+/g, " ")
        .trim();
      if (heading && headings.at(-1) !== heading) headings.push(heading);
    };
    state.__finderHeadingHistory = headings;
    new MutationObserver(recordHeading).observe(document.body, {
      childList: true,
      characterData: true,
      subtree: true,
    });
    recordHeading();
  });
  await fillExpressionSearch(page, "Pintor em Curitiba");
  const searchResponsePromise = page.waitForResponse(
    (response) =>
      response.url().includes("/api/v1/public/professional-searches") &&
      response.request().method() === "POST",
  );
  await page.getByRole("button", { name: "Encontrar" }).click();
  const searchResponse = await searchResponsePromise;
  expect(searchResponse.status()).toBe(200);
  const searchPayload = await searchResponse.json();
  expect(searchPayload.data.interpretation.effective_location).toMatchObject({
    city_code: "4106902",
    state_code: "PR",
    city: "Curitiba",
  });

  await expect(page).toHaveURL(
    /\/encontrar\/pr\/curitiba\?expressao=[A-Za-z0-9_-]+$/,
  );
  await expect(
    page.getByRole("heading", { level: 1, name: /pintor em curitiba/i }),
  ).toBeVisible();
  await expect(page.getByText(/buscando em\s+curitiba, pr/i)).toBeVisible();
  await expect(
    page.getByText(
      /\d+ (?:profissional encontrado|profissionais encontrados)/i,
    ),
  ).toBeVisible();
  expect(searchRequests).toHaveLength(1);
  expect(searchRequests[0]?.postDataJSON()).toMatchObject({
    expression: "Pintor em Curitiba",
    default_location: { city_code: "4209102" },
  });
  const headingHistory = await page.evaluate(
    () =>
      (
        window as typeof window & {
          __finderHeadingHistory?: string[];
        }
      ).__finderHeadingHistory ?? [],
  );
  expect(headingHistory).toContain("Buscando a ajuda certa para você");
  expect(
    headingHistory.some((heading) =>
      /encontre a ajuda certa em curitiba/i.test(heading),
    ),
  ).toBe(false);
});

test("visitor can search, open a profile, and inspect the WhatsApp redirect", async ({
  page,
  request,
}) => {
  const browserErrors: string[] = [];
  page.on("console", (message) => {
    const isAnonymousSessionProbe =
      message.text() ===
      "Failed to load resource: the server responded with a status of 401 (Unauthorized)";
    if (message.type() === "error" && !isAnonymousSessionProbe) {
      browserErrors.push(message.text());
    }
  });
  page.on("pageerror", (error) => browserErrors.push(error.message));

  await page.goto("/");
  await expect(
    page.getByRole("heading", { level: 1, name: /sua casa em boas mãos/i }),
  ).toBeVisible();

  await page.goto("/encontrar");
  await waitForNuxtHydration(page);
  await expect(page).toHaveURL(/\/encontrar\/sc\/joinville$/);
  await expect(
    page.getByRole("heading", {
      level: 1,
      name: /encontre profissionais em joinville/i,
    }),
  ).toBeVisible();
  await expect(
    page.getByRole("heading", {
      level: 2,
      name: /conte o que você precisa resolver/i,
    }),
  ).toBeVisible();
  await expect(
    page.getByText(
      /\d+ (?:profissional encontrado|profissionais encontrados)/i,
    ),
  ).toHaveCount(0);

  await fillExpressionSearch(page, "Preciso de um eletricista em Joinville");
  await page.getByRole("button", { name: "Encontrar" }).click();
  await expect(page).toHaveURL(
    /\/encontrar\/sc\/joinville\?expressao=[A-Za-z0-9_-]+$/,
  );
  await expect(
    page.getByText(
      /\d+ (?:profissional encontrado|profissionais encontrados)/i,
    ),
  ).toBeVisible();
  await expect(page.getByText("Seu pedido", { exact: true })).toHaveCount(0);
  const interpretedFilters = page.getByLabel("Filtros interpretados");
  if ((page.viewportSize()?.width ?? 0) > 800) {
    await expect(interpretedFilters.getByText("Eletricista")).toBeVisible();
    await expect(interpretedFilters.getByText("Joinville - SC")).toBeVisible();
    await expect(
      interpretedFilters.getByText("Como ordenamos", { exact: true }),
    ).toBeVisible();
  } else {
    await expect(interpretedFilters).toBeHidden();
  }
  await expect(
    page.getByText("Marcos Alves", { exact: true }).first(),
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
  expect(new URL(contactUrl!).searchParams.get("request_message")).toBe(
    "Eu preciso de eletricista em Joinville, SC.",
  );

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
  expect(new URL(redirect.headers().location).searchParams.get("text")).toBe(
    "Olá, Marcos Alves! Encontrei seu perfil na Berufe. " +
      "Eu preciso de eletricista em Joinville, SC.",
  );
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

  await page.getByRole("link", { name: "Fazer depois" }).click();
  await expect(page).toHaveURL(/\/app\/professional$/);
  await expect(page.getByRole("heading", { level: 1 })).toContainText("Marcos");
});

test("professional completes onboarding and retains the published state", async ({
  page,
}, testInfo) => {
  const professionalPhone = syntheticPhone(testInfo.project.name, 2);
  await completeProfessionalSignIn(page, professionalPhone);

  await page.getByLabel("Data de nascimento").fill("1990-04-12");
  await page
    .getByLabel("Frase de apresentação")
    .fill("Elétrica residencial com cuidado e clareza.");
  await page
    .getByLabel("Conte um pouco sobre seu trabalho")
    .fill("Trabalho com instalações e manutenção elétrica residencial.");
  await page
    .locator(".profile-photo-control__input")
    .setInputFiles("public/images/professional-marcos-alves-electrician.jpg");
  await expect(
    page.getByText(/Foto salva e aguardando revisão|Foto revisada/),
  ).toBeVisible({ timeout: 30_000 });
  await page.getByRole("button", { name: "Salvar e continuar" }).click();

  await expect(
    page.getByRole("heading", { name: "Escolha o que você oferece." }),
  ).toBeVisible();
  await page.getByRole("button", { name: /Eletricista/ }).click();
  await page.getByLabel("Estado").selectOption("42");
  await page.getByLabel("Cidade").selectOption("4209102");
  await page.getByLabel("Atendo em toda Joinville").check();
  await page.getByRole("button", { name: "Salvar e continuar" }).click();

  await expect(
    page.getByRole("heading", { name: "Quer verificar sua identidade?" }),
  ).toBeVisible();
  await page
    .locator('input[name="identity-document"]')
    .setInputFiles("public/images/professional-marcos-alves-electrician.jpg");
  await page.getByRole("button", { name: "Enviar e concluir" }).click();
  await expect(page.getByText("Verificação enviada")).toBeVisible();
  await expect(page.getByText("100% completo", { exact: true })).toBeVisible();

  const publishResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith("/api/v1/professional/profile/submission") &&
      response.request().method() === "POST",
  );
  await page.getByRole("button", { name: "Publicar perfil" }).click();
  expect((await publishResponse).status()).toBe(200);

  await expect(
    page.getByRole("heading", {
      name: "Seu perfil já pode ser encontrado.",
    }),
  ).toBeVisible();

  await page
    .locator("header")
    .getByRole("link", { name: "Berufe — início" })
    .click();
  await expect(page).toHaveURL(/\/$/);
  const isMobileHeader = (page.viewportSize()?.width ?? 0) <= 900;
  const workspaceAction = isMobileHeader
    ? page.locator(".header__mobile-login")
    : page.locator(".header__desktop-auth").getByRole("link", {
        name: "Ir ao painel",
        exact: true,
      });
  await expect(workspaceAction).toBeVisible();
  await expect(workspaceAction).toHaveAttribute("href", "/app/professional");
  await expect(
    page.getByRole("heading", { name: "Acesse seu perfil." }),
  ).toHaveCount(0);
  await workspaceAction.click();
  await expect(page).toHaveURL(/\/app\/professional$/);
  await expect(
    page.getByRole("heading", { level: 1, name: /Olá, Marcos/i }),
  ).toBeVisible();

  await page.goto("/app/professional/onboarding");
  await expect(page).toHaveURL(/\/app\/professional$/);
  await expect(
    page.getByRole("heading", { name: /deixar seu perfil pronto/i }),
  ).toHaveCount(0);
});
