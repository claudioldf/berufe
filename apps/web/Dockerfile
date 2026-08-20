FROM node:24.18.0-bookworm-slim

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

RUN npm install --global pnpm@10.34.5

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
RUN pnpm exec playwright install --with-deps chromium

COPY . .

CMD ["pnpm", "dev", "--host", "0.0.0.0", "--port", "3000"]
