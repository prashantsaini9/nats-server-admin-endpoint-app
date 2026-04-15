# ═══════════════════════════════════════════════════════════
# D-Secure NATS Server — Docker Image for Render
# ═══════════════════════════════════════════════════════════

FROM nats:2.10-alpine

# Install curl for healthchecks + sed for config substitution
RUN apk add --no-cache curl sed

# Create required directories
RUN mkdir -p /data/jetstream /etc/nats

# Copy configuration and startup script
COPY nats-server.conf /etc/nats/nats-server.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose ports (Render only exposes one publicly via PORT env)
# WebSocket = PORT (public), 4222 = NATS TCP (internal), 8222 = monitoring (internal)
EXPOSE 4222 8222

# Health check via monitoring endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -sf http://localhost:8222/healthz || exit 1

# Use start.sh to substitute env vars and launch
ENTRYPOINT ["/start.sh"]
