import {
  defineRailway,
  github,
  postgres,
  preserve,
  project,
  service,
} from "railway/iac";

export default defineRailway(() => {
  const database = postgres("Postgres");

  const api = service("api", {
    source: github("claudioldf/berufe", { branch: "production" }),
    build: {
      builder: "DOCKERFILE",
      dockerfilePath: "apps/api/Dockerfile",
      watchPatterns: [
        "/apps/api/**",
        "/apps/web/data/catalogs.json",
        "/.railway/**",
      ],
    },
    deploy: {
      preDeployCommand: ["bin/rails db:prepare db:seed"],
      healthcheckPath: "/up",
      healthcheckTimeout: 300,
      restartPolicyType: "ALWAYS",
      multiRegionConfig: {
        "us-east4-eqdc4a": { numReplicas: 1 },
      },
    },
    env: {
      BERUFE_ENV: "production",
      RAILS_ENV: "production",
      PORT: "8080",
      DATABASE_URL: database.env.DATABASE_URL,
      SECRET_KEY_BASE: preserve(),
      RAILS_MAX_THREADS: "3",
      DB_POOL: "7",
      WEB_ORIGIN: "https://www.berufe.com.br",
      API_PUBLIC_URL: "https://api.berufe.com.br",
      PRODUCT_LAUNCH_DATE: preserve(),
      MAXMIND_ACCOUNT_ID: preserve(),
      MAXMIND_LICENSE_KEY: preserve(),
      SMS_OTP_ADAPTER: "infobip",
      INFOBIP_BASE_URL: preserve(),
      INFOBIP_API_KEY: preserve(),
      INFOBIP_2FA_APPLICATION_ID: preserve(),
      INFOBIP_2FA_MESSAGE_ID: preserve(),
      INFOBIP_SENDER: preserve(),
      INFOBIP_CREDENTIAL_SCOPE: "production",
      MEDIA_STORAGE_ADAPTER: "r2",
      R2_ENDPOINT: preserve(),
      R2_ACCESS_KEY_ID: preserve(),
      R2_SECRET_ACCESS_KEY: preserve(),
      R2_PUBLIC_BUCKET: "berufe-production-public",
      R2_PRIVATE_BUCKET: "berufe-production-private",
      SMTP_ADDRESS: "smtp.resend.com",
      SMTP_PORT: "587",
      SMTP_DOMAIN: "berufe.com.br",
      SMTP_USERNAME: "resend",
      SMTP_PASSWORD: preserve(),
      SMTP_AUTHENTICATION: "plain",
      SMTP_STARTTLS: "true",
      MAIL_FROM: "Berufe <nao-responda@berufe.com.br>",
      GOOD_JOB_EXECUTION_MODE: "async",
      GOOD_JOB_MAX_THREADS: "1",
      GOOD_JOB_QUEUES: "default",
      BUGSNAG_API_KEY: preserve(),
    },
  });

  const web = service("web", {
    source: github("claudioldf/berufe", {
      branch: "production",
      rootDirectory: "apps/web",
    }),
    build: {
      builder: "DOCKERFILE",
      dockerfilePath: "Dockerfile",
      watchPatterns: ["/apps/web/**", "/.railway/**"],
    },
    deploy: {
      healthcheckPath: "/health",
      healthcheckTimeout: 300,
      restartPolicyType: "ALWAYS",
      multiRegionConfig: {
        "us-east4-eqdc4a": { numReplicas: 1 },
      },
    },
    env: {
      PORT: "8080",
      NUXT_API_INTERNAL_BASE_URL:
        "http://${{api.RAILWAY_PRIVATE_DOMAIN}}:${{api.PORT}}",
      NUXT_PUBLIC_API_BASE_URL: "https://api.berufe.com.br",
      NUXT_PUBLIC_SITE_URL: "https://www.berufe.com.br",
      NUXT_PUBLIC_BUGSNAG_API_KEY: preserve(),
    },
  });

  return project("berufe-production", {
    resources: [database, api, web],
  });
});
