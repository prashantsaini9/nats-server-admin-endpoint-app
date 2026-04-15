#!/bin/sh
# ═══════════════════════════════════════════════════════════
# D-Secure NATS — Render Startup Script
# ═══════════════════════════════════════════════════════════
# 
# Render provides $PORT env var. NATS config doesn't 
# natively support env vars, so we substitute at runtime.
# ═══════════════════════════════════════════════════════════

set -e

# Default values
NATS_WS_PORT="${PORT:-10000}"
NATS_TOKEN="${NATS_AUTH_TOKEN:-dsecure_dev_token_2024}"

echo "════════════════════════════════════════════"
echo "  D-Secure NATS Server"
echo "════════════════════════════════════════════"
echo "  WebSocket Port : $NATS_WS_PORT"
echo "  Auth Token     : ${NATS_TOKEN:0:8}..."
echo "  JetStream      : /data/jetstream"
echo "════════════════════════════════════════════"

# Create data directories
mkdir -p /data/jetstream

# Substitute placeholders in config
cp /etc/nats/nats-server.conf /tmp/nats-runtime.conf
sed -i "s/NATS_WS_PORT_PLACEHOLDER/$NATS_WS_PORT/g" /tmp/nats-runtime.conf
sed -i "s/NATS_AUTH_TOKEN_PLACEHOLDER/$NATS_TOKEN/g" /tmp/nats-runtime.conf

echo ""
echo "Starting NATS server..."
echo ""

# Start NATS with runtime config
exec nats-server -c /tmp/nats-runtime.conf
