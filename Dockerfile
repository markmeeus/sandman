# ==============================
# Builder Stage
# ==============================
FROM hexpm/elixir:1.18.4-erlang-28.2-alpine-3.21.5 AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    npm

# Set build ENV
ENV MIX_ENV=prod

# Create app directory and copy files
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

# Copy application code
COPY priv priv
COPY lib lib
COPY assets assets
COPY config config

# Compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Build the release
RUN mix release

# ==============================
# Runtime Stage
# ==============================
FROM alpine:3.21 AS app

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++

# Create a non-root user
RUN addgroup -g 1000 sandman && \
    adduser -D -u 1000 -G sandman sandman

WORKDIR /app

# Set runtime ENV
ENV MIX_ENV=prod \
    PHX_SERVER=true \
    PORT=4000 \
    LOG_LEVEL=info \
    BIND_ALL_INTERFACES=true \
    DEFAULT_FILE_PICKER_PATH=/data

# Copy the release from builder stage
COPY --from=builder --chown=sandman:sandman /app/_build/prod/rel/sandman ./

# Create data directory for user files
RUN mkdir -p /data && chown sandman:sandman /data

# Switch to non-root user
USER sandman

# Expose port
EXPOSE 4000

# Volume for persistent data
VOLUME ["/data"]

# Start the application
CMD ["bin/sandman", "start"]

