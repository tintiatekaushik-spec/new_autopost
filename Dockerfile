# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim AS web-build
WORKDIR /app

ARG VITE_BROWSER_DESKTOP_URL=auto
ENV VITE_BROWSER_DESKTOP_URL=${VITE_BROWSER_DESKTOP_URL}

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:1.27-alpine AS web
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=web-build /app/dist /usr/share/nginx/html
EXPOSE 80

FROM mcr.microsoft.com/playwright:v1.61.0-noble AS api
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=4100
ENV UPLOAD_DIR=/app/uploads
ENV UPLOAD_MAX_FILE_BYTES=1073741824
ENV CHROME_PATH=/usr/bin/google-chrome
ENV CHROME_NO_SANDBOX=true
ENV DISPLAY=:99
ENV DISPLAY_RESOLUTION=1920x1080x24

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    fluxbox \
    fonts-liberation \
    fonts-noto-color-emoji \
    novnc \
    websockify \
    x11vnc \
    xvfb \
  && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --omit=dev \
  && npx playwright install chrome \
  && if ! command -v google-chrome >/dev/null 2>&1; then \
    chrome_bin="$(find /ms-playwright /opt /usr -type f -name chrome 2>/dev/null | head -n 1)"; \
    test -n "$chrome_bin"; \
    ln -sf "$chrome_bin" /usr/bin/google-chrome; \
  fi \
  && google-chrome --version

COPY server ./server
COPY shared ./shared
COPY tsconfig.json ./
COPY docker/start-api.sh /usr/local/bin/start-api.sh

RUN mkdir -p /app/uploads /app/browser-data /app/data \
  && chmod +x /usr/local/bin/start-api.sh

VOLUME ["/app/uploads", "/app/browser-data", "/app/data"]
EXPOSE 4100 6080
CMD ["/usr/local/bin/start-api.sh"]

FROM postgres:16-alpine AS db
COPY supabase/migrations /docker-entrypoint-initdb.d
