FROM node:20-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
# Common dependencies environment

FROM base AS dependencies-env
COPY . /app

# Development dependencies

FROM dependencies-env AS development-dependencies-env
COPY ./package.json pnpm-lock.yaml /app/
WORKDIR /app
RUN pnpm install --frozen-lockfile

# Production dependencies

FROM dependencies-env AS production-dependencies-env
COPY ./package.json pnpm-lock.yaml /app/
WORKDIR /app
RUN pnpm install --prod --frozen-lockfile

# Build environment

FROM dependencies-env AS build-env
COPY ./package.json pnpm-lock.yaml /app/
COPY --from=development-dependencies-env /app/node_modules /app/node_modules
WORKDIR /app
RUN pnpm build
RUN ls

# Final production image

FROM tianon/true
COPY --from=build-env /app/dist /dist
RUN ["/true"]
