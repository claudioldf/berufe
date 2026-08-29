FROM node:24.18.0-bookworm-slim AS base

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH

# better-sqlite3 (a @nuxt/content dependency) has no prebuilt binary yet for
# this Node version, so pnpm falls back to compiling it from source.
RUN apt-get update && apt-get install --no-install-recommends -y \
    python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

RUN npm install --global pnpm@10.34.5

WORKDIR /app

FROM base AS dependencies

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

FROM dependencies AS development

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

RUN pnpm exec playwright install --with-deps chromium

COPY . .

CMD ["pnpm", "dev", "--host", "0.0.0.0", "--port", "3000"]

FROM dependencies AS build

COPY . .
RUN rm -rf .nuxt .output && pnpm build

FROM node:24.18.0-bookworm-slim AS production

ENV HOST=0.0.0.0 \
    NODE_ENV=production \
    PORT=3000

WORKDIR /app

COPY --chown=node:node --from=build /app/.output ./.output

USER node

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]
