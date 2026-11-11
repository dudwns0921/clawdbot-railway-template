FROM node:24-bookworm
ENV NODE_ENV=production

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates tini python3 python3-venv git \
  && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@10.23.0 --activate

# 소스 빌드 대신 npm에 올라온 빌드본을 받는다. 아래 NPM_CONFIG_PREFIX(/data)보다 먼저 설치해야 이미지에 들어간다.
ARG OPENCLAW_VERSION=2026.11.2
RUN npm install -g --prefix /opt/openclaw "openclaw@${OPENCLAW_VERSION}" && npm cache clean --force
ENV OPENCLAW_ENTRY=/opt/openclaw/lib/node_modules/openclaw/openclaw.mjs
RUN printf '%s\n' '#!/usr/bin/env bash' 'exec node /opt/openclaw/lib/node_modules/openclaw/openclaw.mjs "$@"' > /usr/local/bin/openclaw \
  && chmod +x /usr/local/bin/openclaw

ENV NPM_CONFIG_PREFIX=/data/npm
ENV NPM_CONFIG_CACHE=/data/npm-cache
ENV PNPM_HOME=/data/pnpm
ENV PNPM_STORE_DIR=/data/pnpm-store
ENV PATH="/data/npm/bin:/data/pnpm:${PATH}"

WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY src ./src

EXPOSE 8080
ENTRYPOINT ["tini", "--"]
CMD ["node", "src/server.js"]
