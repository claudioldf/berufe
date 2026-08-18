import { defineConfig, devices } from "@playwright/test";

const serverPort = process.env.PLAYWRIGHT_PORT ?? "4173";
const baseUrl =
  process.env.PLAYWRIGHT_BASE_URL ?? `http://127.0.0.1:${serverPort}`;

export default defineConfig({
  testDir: "tests/e2e",
  fullyParallel: true,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? "github" : "list",
  use: {
    baseURL: baseUrl,
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
    {
      name: "mobile-chromium",
      use: { ...devices["Pixel 7"] },
    },
  ],
  webServer: {
    command: "npm run build && node .output/server/index.mjs",
    env: {
      NITRO_HOST: "127.0.0.1",
      NITRO_PORT: serverPort,
    },
    url: baseUrl,
    reuseExistingServer: !process.env.CI,
    timeout: 180_000,
  },
});
