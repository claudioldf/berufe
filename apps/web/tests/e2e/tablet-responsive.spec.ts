import { expect, test, type Locator, type Page } from "@playwright/test";

const phoneRun = (Math.floor(Math.random() * 900) + 100).toString();

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

async function registerProfessional(page: Page) {
  await page.goto("/app/professional/login");
  await waitForNuxtHydration(page);
  await page.getByLabel("Celular com DDD").fill(`4793${phoneRun}0001`);
  await page.getByRole("button", { name: "Receber código" }).click();
  await page.getByLabel("Código de 6 dígitos").fill("123456");
  await page.getByRole("button", { name: "Confirmar e continuar" }).click();
  await page.getByLabel("Nome profissional").fill("Marina Costa");
  await page.getByLabel(/li e aceito/i).check();
  await page.getByRole("button", { name: "Criar meu perfil" }).click();
  await expect(page).toHaveURL(/\/app\/professional\/onboarding$/);
}

async function boundingBox(locator: Locator) {
  const box = await locator.boundingBox();
  expect(box).not.toBeNull();
  return box!;
}

async function expectNoHorizontalOverflow(page: Page) {
  const widths = await page.evaluate(() => ({
    client: document.documentElement.clientWidth,
    scroll: document.documentElement.scrollWidth,
  }));
  expect(widths.scroll).toBeLessThanOrEqual(widths.client);
}

async function expectFeaturedPhotoFillsMedia(page: Page) {
  const media = page
    .locator(".featured-card__image:has(.avatar__image)")
    .first();
  const image = media.locator(".avatar__image");

  await media.scrollIntoViewIfNeeded();
  await expect(image).toBeVisible();
  await expect
    .poll(() =>
      image.evaluate(
        (element) =>
          (element as HTMLImageElement).complete &&
          (element as HTMLImageElement).naturalWidth > 0,
      ),
    )
    .toBe(true);

  const mediaBox = await boundingBox(media);
  const imageBox = await boundingBox(image);

  expect(Math.abs(imageBox.x - mediaBox.x)).toBeLessThanOrEqual(1);
  expect(Math.abs(imageBox.y - mediaBox.y)).toBeLessThanOrEqual(1);
  expect(Math.abs(imageBox.width - mediaBox.width)).toBeLessThanOrEqual(1);
  expect(Math.abs(imageBox.height - mediaBox.height)).toBeLessThanOrEqual(1);
  expect(Math.abs(mediaBox.height / mediaBox.width - 1.25)).toBeLessThanOrEqual(
    0.01,
  );

  return mediaBox;
}

async function expectStacked(upper: Locator, lower: Locator) {
  const upperBox = await boundingBox(upper);
  const lowerBox = await boundingBox(lower);
  expect(lowerBox.y).toBeGreaterThanOrEqual(upperBox.y + upperBox.height);
  expect(Math.abs(upperBox.x - lowerBox.x)).toBeLessThanOrEqual(1);
  expect(Math.abs(upperBox.width - lowerBox.width)).toBeLessThanOrEqual(1);
}

async function expectAlignedBelow(upper: Locator, lower: Locator) {
  const upperBox = await boundingBox(upper);
  const lowerBox = await boundingBox(lower);
  expect(lowerBox.y).toBeGreaterThanOrEqual(upperBox.y + upperBox.height);
  expect(Math.abs(upperBox.x - lowerBox.x)).toBeLessThanOrEqual(1);
}

async function expectSideBySide(left: Locator, right: Locator) {
  const leftBox = await boundingBox(left);
  const rightBox = await boundingBox(right);
  expect(rightBox.x).toBeGreaterThanOrEqual(leftBox.x + leftBox.width);
  expect(Math.abs(leftBox.y - rightBox.y)).toBeLessThanOrEqual(1);
}

async function expectSameWidth(outer: Locator, inner: Locator) {
  const outerBox = await boundingBox(outer);
  const innerBox = await boundingBox(inner);
  expect(Math.abs(outerBox.x - innerBox.x)).toBeLessThanOrEqual(1);
  expect(Math.abs(outerBox.width - innerBox.width)).toBeLessThanOrEqual(1);
}

async function expectStatusContentFollowsIcon(status: Locator) {
  const iconBox = await boundingBox(status.locator(".status-banner__icon"));
  const contentBox = await boundingBox(
    status.locator(".status-banner__content"),
  );
  expect(contentBox.x - (iconBox.x + iconBox.width)).toBeLessThanOrEqual(16);
}

async function expectQuickActionsOnOneRow(
  quickActions: Locator,
  orientation: "horizontal" | "vertical" = "horizontal",
) {
  const boxes = await quickActions
    .locator(".actions-card__list > *")
    .evaluateAll((actions) =>
      actions.map((action) => {
        const box = action.getBoundingClientRect();
        const iconBox = action
          .querySelector(".actions-card__icon")!
          .getBoundingClientRect();
        const labelBox = action
          .querySelector("strong")!
          .getBoundingClientRect();
        return {
          top: Math.round(box.top),
          height: box.height,
          width: box.width,
          iconBottom: iconBox.bottom,
          iconRight: iconBox.right,
          iconCenterX: iconBox.left + iconBox.width / 2,
          iconCenterY: iconBox.top + iconBox.height / 2,
          labelLeft: labelBox.left,
          labelTop: labelBox.top,
          labelCenterX: labelBox.left + labelBox.width / 2,
          labelCenterY: labelBox.top + labelBox.height / 2,
        };
      }),
    );

  expect(boxes).toHaveLength(5);
  expect(new Set(boxes.map((box) => box.top)).size).toBe(1);
  expect(boxes.every((box) => box.width >= 44)).toBe(true);
  expect(boxes.every((box) => box.height <= 64)).toBe(true);
  if (orientation === "horizontal") {
    expect(boxes.every((box) => box.labelLeft >= box.iconRight)).toBe(true);
    expect(
      boxes.every((box) => Math.abs(box.iconCenterY - box.labelCenterY) <= 1),
    ).toBe(true);
    return;
  }
  expect(boxes.every((box) => box.labelTop >= box.iconBottom)).toBe(true);
  expect(
    boxes.every((box) => Math.abs(box.iconCenterX - box.labelCenterX) <= 1),
  ).toBe(true);
}

async function expectProgressStepsOnOneRow(page: Page) {
  const tops = await page
    .locator(".onboarding-progress nav button")
    .evaluateAll((buttons) =>
      buttons.map((button) => Math.round(button.getBoundingClientRect().top)),
    );
  expect(new Set(tops).size).toBe(1);
}

async function expectProgressStepsStacked(page: Page) {
  const boxes = await page
    .locator(".onboarding-progress nav button")
    .evaluateAll((buttons) =>
      buttons.map((button) => {
        const box = button.getBoundingClientRect();
        return { left: Math.round(box.left), top: Math.round(box.top) };
      }),
    );
  expect(new Set(boxes.map((box) => box.left)).size).toBe(1);
  expect(boxes[1]!.top).toBeGreaterThan(boxes[0]!.top);
  expect(boxes[2]!.top).toBeGreaterThan(boxes[1]!.top);
}

test("featured professional photos fill portrait cards across responsive layouts", async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto("/");
  await waitForNuxtHydration(page);
  await expect(
    page.getByRole("heading", {
      level: 2,
      name: "Veja quem atende na sua região.",
    }),
  ).toBeVisible();

  await expectFeaturedPhotoFillsMedia(page);
  await expectNoHorizontalOverflow(page);

  await page.setViewportSize({ width: 760, height: 1024 });
  const tabletCard = await boundingBox(page.locator(".featured-card").first());
  const tabletGrid = await boundingBox(page.locator(".featured__grid"));
  expect(tabletCard.width).toBeLessThanOrEqual(450);
  expect(
    Math.abs(
      tabletCard.x - (tabletGrid.x + (tabletGrid.width - tabletCard.width) / 2),
    ),
  ).toBeLessThanOrEqual(1);
  await expectFeaturedPhotoFillsMedia(page);
  await expectNoHorizontalOverflow(page);

  await page.setViewportSize({ width: 390, height: 844 });
  const phoneCard = await boundingBox(page.locator(".featured-card").first());
  const phoneGrid = await boundingBox(page.locator(".featured__grid"));
  expect(Math.abs(phoneCard.width - phoneGrid.width)).toBeLessThanOrEqual(1);
  await expectFeaturedPhotoFillsMedia(page);
  await expectNoHorizontalOverflow(page);
});

test("onboarding and dashboard remain spacious across responsive layouts", async ({
  page,
}) => {
  test.setTimeout(60_000);
  await registerProfessional(page);

  const progress = page.locator(".onboarding-progress");
  const panel = page.locator(".onboarding-panel");

  await expectStacked(progress, panel);
  await expectProgressStepsOnOneRow(page);
  await expectNoHorizontalOverflow(page);

  await page.setViewportSize({ width: 834, height: 1194 });
  await expectStacked(progress, panel);
  await expectProgressStepsOnOneRow(page);
  await expectNoHorizontalOverflow(page);

  await page.setViewportSize({ width: 1280, height: 900 });
  await expectSideBySide(progress, panel);
  await expectNoHorizontalOverflow(page);

  await page.setViewportSize({ width: 390, height: 844 });
  await expectStacked(progress, panel);
  await expectProgressStepsStacked(page);
  await expectNoHorizontalOverflow(page);

  await page.setViewportSize({ width: 1024, height: 1366 });
  await page.getByRole("link", { name: "Fazer depois" }).click();
  await expect(page).toHaveURL(/\/app\/professional$/);
  await expect(
    page.getByRole("heading", { level: 1, name: /Olá, Marina/i }),
  ).toBeVisible();

  const status = page.locator(".status-banner");
  const operational = page.locator(".dashboard-operational");
  const sidebar = page.locator(".dashboard-sidebar");
  const checklist = page.locator(".checklist-card");
  const quickActions = page.locator(".actions-card");
  const recentWork = page.locator(".dashboard-operational .recent-work");
  const welcomeIntro = page.locator(".dashboard-welcome__inner > div").first();
  const welcomeActions = page.locator(".dashboard-welcome__actions");

  await expectStacked(quickActions, status);
  await expectStacked(status, operational);
  await expectStacked(operational, sidebar);
  await expectStatusContentFollowsIcon(status);
  await expectSameWidth(operational, recentWork);
  await expectSameWidth(sidebar, checklist);
  await expectQuickActionsOnOneRow(quickActions);
  await expectNoHorizontalOverflow(page);

  await page.setViewportSize({ width: 834, height: 1194 });
  await expectAlignedBelow(welcomeIntro, welcomeActions);
  await expectStacked(quickActions, status);
  await expectStatusContentFollowsIcon(status);
  await expectSameWidth(operational, recentWork);
  await expectSameWidth(sidebar, checklist);
  await expectQuickActionsOnOneRow(quickActions);
  await expectNoHorizontalOverflow(page);

  await page.setViewportSize({ width: 1280, height: 900 });
  await expectStacked(quickActions, status);
  await expectStacked(status, page.locator(".dashboard-layout"));
  const desktopSidebarBox = await boundingBox(sidebar);
  const desktopOperationalBox = await boundingBox(operational);
  expect(desktopOperationalBox.x).toBeGreaterThan(
    desktopSidebarBox.x + desktopSidebarBox.width,
  );
  expect(
    Math.abs(desktopSidebarBox.y - desktopOperationalBox.y),
  ).toBeLessThanOrEqual(1);
  await expectQuickActionsOnOneRow(quickActions);
  await expectNoHorizontalOverflow(page);

  await page.setViewportSize({ width: 390, height: 844 });
  await expectAlignedBelow(welcomeIntro, welcomeActions);
  await expectStacked(quickActions, status);
  await expectStacked(status, operational);
  await expectStacked(operational, sidebar);
  await expectStatusContentFollowsIcon(status);
  await expectSameWidth(operational, recentWork);
  await expectSameWidth(sidebar, checklist);
  await expectQuickActionsOnOneRow(quickActions, "vertical");
  await expect(
    page.locator(".dashboard-operational .feature-empty__visual"),
  ).toBeHidden();
  await expectNoHorizontalOverflow(page);
});
