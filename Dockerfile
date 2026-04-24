# ─── Stage 1: Builder ───────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first — Docker layer cache optimization
# If only source code changes, this layer is reused from cache
COPY package*.json ./

# Install all dependencies including devDependencies
RUN npm ci --frozen-lockfile

# Copy source code
COPY src/ ./src/

# ─── Stage 2: Production ────────────────────────────────────────
FROM node:20-alpine AS production

# Never run as root inside containers
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --frozen-lockfile --only=production && \
    npm cache clean --force

# Copy source from builder stage
COPY --from=builder /app/src ./src

# Set ownership before switching user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Document port
EXPOSE 3000

# Image metadata
LABEL maintainer="devops-team" \
      version="1.0.0" \
      description="DevOps API Service"

# Exec form — ensures SIGTERM reaches Node directly
# Shell form wraps in /bin/sh which swallows signals
CMD ["node", "src/app.js"]
