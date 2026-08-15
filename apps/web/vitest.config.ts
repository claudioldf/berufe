import { defineVitestConfig } from "@nuxt/test-utils/config";

export default defineVitestConfig({
  test: {
    environment: "nuxt",
    globals: true,
    hookTimeout: 30_000,
    include: ["tests/unit/**/*.test.ts"],
    maxWorkers: 1,
    coverage: {
      provider: "v8",
      reporter: ["text-summary", "html"],
      include: [
        "app/components/**/*.vue",
        "app/composables/**/*.ts",
        "app/services/api/{application-session,catalog,client,errors,phone-auth}.ts",
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
