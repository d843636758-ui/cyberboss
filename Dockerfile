FROM node:22-bookworm-slim

ENV NODE_ENV=production \
    HOME=/data \
    CYBERBOSS_STATE_DIR=/data/.cyberboss \
    CYBERBOSS_WORKSPACE_ROOT=/data/workspace \
    CYBERBOSS_RUNTIME=codex \
    CYBERBOSS_ENABLE_LOCATION_SERVER=false

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/* \
    && npm install --global @openai/codex@latest \
    && npm cache clean --force \
    && rm -rf /root/.cache /tmp/*

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev \
    && npm cache clean --force \
    && rm -rf /root/.cache /tmp/*

COPY . .
RUN chmod +x /app/scripts/zeabur-entrypoint.sh

VOLUME ["/data"]

ENTRYPOINT ["/app/scripts/zeabur-entrypoint.sh"]
