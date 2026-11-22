# ---- Stage 1: compile TypeScript --------------------------------------------
FROM node:26-alpine AS build
WORKDIR /app

# Copy the manifests first so this layer is cached until dependencies change.
COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build

# ---- Stage 2: small runtime image -------------------------------------------
FROM node:26-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app

# Production dependencies only: no TypeScript compiler, no test tools.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build /app/dist ./dist

# The pipeline passes the git commit SHA, so every image knows its own version.
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    PORT=3000

# Never run as root inside the container.
USER node
EXPOSE 3000

# Exec form: node receives SIGTERM directly and can shut down cleanly.
CMD ["node", "dist/server.js"]