FROM node:24.18.0-bookworm-slim

RUN npm install --global pnpm@10.34.5

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

CMD ["pnpm", "dev", "--host", "0.0.0.0", "--port", "3000"]
