#!/bin/bash
# ═══════════════════════════════════════════════════════════
# D-Secure — JetStream Setup Script
# ═══════════════════════════════════════════════════════════
#
# Run this ONCE after deploying NATS to Render.
# Requires: nats CLI (https://github.com/nats-io/natscli)
#
# Install nats CLI:
#   choco install nats (Windows)
#   brew install nats-io/nats-tools/nats (macOS)
# ═══════════════════════════════════════════════════════════

# ── Configuration ──
# Replace with your actual Render URL after deployment
NATS_URL="wss://dsecure-nats.onrender.com"
NATS_TOKEN="dsecure_dev_token_2024"

echo "═══════════════════════════════════════════"
echo "  D-Secure JetStream Setup"
echo "═══════════════════════════════════════════"
echo "  Server: $NATS_URL"
echo "═══════════════════════════════════════════"
echo ""

# ── 1. HEARTBEATS Stream (Memory — ephemeral, fast) ──
echo "💓 Creating HEARTBEATS stream..."
nats stream add HEARTBEATS \
  --subjects "tenant.*.endpoint.*.heartbeat" \
  --storage memory \
  --retention limits \
  --max-age 5m \
  --max-msgs-per-subject 5 \
  --max-bytes 50MB \
  --replicas 1 \
  --discard old \
  --server "$NATS_URL" \
  --creds "" \
  --user "" \
  --password "$NATS_TOKEN" \
  2>/dev/null || echo "  (Stream may already exist)"

# ── 2. COMMANDS Stream (File — persistent, reliable delivery) ──
echo "⚡ Creating COMMANDS stream..."
nats stream add COMMANDS \
  --subjects "tenant.*.admin.command.*,tenant.*.admin.broadcast,tenant.*.admin.settings" \
  --storage file \
  --retention workqueue \
  --max-age 24h \
  --max-msgs 100000 \
  --max-bytes 500MB \
  --replicas 1 \
  --discard old \
  --dupe-window 2m \
  --server "$NATS_URL" \
  --password "$NATS_TOKEN" \
  2>/dev/null || echo "  (Stream may already exist)"

# ── 3. RESPONSES Stream (File — command responses from endpoints) ──
echo "📩 Creating RESPONSES stream..."
nats stream add RESPONSES \
  --subjects "tenant.*.endpoint.*.response" \
  --storage file \
  --retention limits \
  --max-age 1h \
  --max-msgs 50000 \
  --max-bytes 200MB \
  --replicas 1 \
  --discard old \
  --server "$NATS_URL" \
  --password "$NATS_TOKEN" \
  2>/dev/null || echo "  (Stream may already exist)"

# ── 4. ACTIVITY Stream (File — activity logs) ──
echo "📝 Creating ACTIVITY stream..."
nats stream add ACTIVITY \
  --subjects "tenant.*.endpoint.*.activity,tenant.*.endpoint.*.metrics,tenant.*.endpoint.*.status" \
  --storage file \
  --retention limits \
  --max-age 7d \
  --max-msgs 500000 \
  --max-bytes 500MB \
  --replicas 1 \
  --discard old \
  --server "$NATS_URL" \
  --password "$NATS_TOKEN" \
  2>/dev/null || echo "  (Stream may already exist)"

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ JetStream Setup Complete!"
echo "═══════════════════════════════════════════"
echo ""

# ── List all streams ──
echo "📊 Active Streams:"
nats stream ls --server "$NATS_URL" --password "$NATS_TOKEN" 2>/dev/null || echo "  Could not list streams"
