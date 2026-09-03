import { defineVitestConfig } from "@nuxt/test-utils/config";

export default defineVitestConfig({
  test: {
    environment: "nuxt",
    globals: true,
    hookTimeout: 30_000,
    include: ["tests/unit/**/*.test.ts"],
    setupFiles: ["tests/unit/setup.ts"],
    maxWorkers: 1,
    coverage: {
      provider: "v8",
      reporter: ["text-summary", "html"],
      include: [
        "app/components/**/*.vue",
        "app/composables/**/*.ts",
        "app/services/api/{admin-catalog,admin-impersonation,admin-moderation,admin-professionals,admin-reports,admin-session,application-session,catalog,client,errors,locations,media-upload,phone-auth,professional-data-erasure,professional-notifications,professional-recommendations,professional-registration,public-discovery}.ts",
        "app/middleware/**/*.ts",
        "app/utils/**/*.ts",
      ],
    },
    environmentOptions: {
      nuxt: {
        domEnvironment: "happy-dom",
        mock: {
          intersectionObserver: true,
        },
      },
    },
  },
});
