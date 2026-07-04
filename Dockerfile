FROM node:22-alpine AS deps

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@11.5.3 --activate

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./

RUN pnpm install --frozen-lockfile

FROM deps AS build

ENV ENABLE_CONTENT_SYNC=false
ENV NODE_ENV=production

COPY . .

RUN pnpm build

FROM nginx:1.27-alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
	CMD wget -qO- http://127.0.0.1/healthz || exit 1
