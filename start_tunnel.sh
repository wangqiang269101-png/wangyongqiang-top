#!/bin/zsh
# Start static site + Cloudflare Tunnel for wangyongqiang.top
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$ROOT/public-site"
BIN="$SITE/bin/cloudflared"
PORT="${SITE_PORT:-8088}"
DOMAIN="wangyongqiang.top"
TUNNEL_NAME="wangyongqiang-top"
CF_DIR="$HOME/.cloudflared"
LOG_DIR="$SITE/logs"
PID_DIR="$SITE/run"

mkdir -p "$LOG_DIR" "$PID_DIR" "$CF_DIR"

if [[ ! -x "$BIN" ]]; then
  echo "cloudflared missing; run build_public_site.py first" >&2
  exit 1
fi

python3 "$ROOT/build_public_site.py"

# Stop previous instances
for f in web.pid tunnel.pid; do
  if [[ -f "$PID_DIR/$f" ]]; then
    kill "$(cat "$PID_DIR/$f")" 2>/dev/null || true
    rm -f "$PID_DIR/$f"
  fi
done
pkill -f "python3 -m http.server $PORT" 2>/dev/null || true

# Start static file server
cd "$SITE"
nohup python3 -m http.server "$PORT" --bind 127.0.0.1 \
  >"$LOG_DIR/web.log" 2>&1 &
echo $! >"$PID_DIR/web.pid"
sleep 1

if ! curl -sf "http://127.0.0.1:$PORT/index.html" >/dev/null; then
  echo "Local web server failed" >&2
  exit 1
fi
echo "local_ok http://127.0.0.1:$PORT/"

# Ensure tunnel exists
if [[ ! -f "$CF_DIR/${TUNNEL_NAME}.json" && ! -f "$CF_DIR/$(ls "$CF_DIR"/*.json 2>/dev/null | head -1)" ]]; then
  echo "Creating tunnel (may require browser login)..."
  "$BIN" tunnel login 2>&1 | tee "$LOG_DIR/login.log" || true
  "$BIN" tunnel create "$TUNNEL_NAME" 2>&1 | tee "$LOG_DIR/create.log" || true
fi

TUNNEL_ID=""
for cred in "$CF_DIR"/*.json; do
  [[ -f "$cred" ]] || continue
  if [[ "$cred" != *"cert.pem"* ]]; then
    TUNNEL_ID="$(basename "$cred" .json)"
    break
  fi
done

if [[ -z "$TUNNEL_ID" ]]; then
  echo "tunnel_not_ready: run cloudflared tunnel login manually" >&2
  exit 2
fi

CONFIG="$CF_DIR/config.yml"
cat >"$CONFIG" <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CF_DIR/${TUNNEL_ID}.json

ingress:
  - hostname: $DOMAIN
    service: http://127.0.0.1:$PORT
  - hostname: www.$DOMAIN
    service: http://127.0.0.1:$PORT
  - service: http_status:404
EOF

echo "config_written $CONFIG"

# Route DNS if domain on Cloudflare
"$BIN" tunnel route dns "$TUNNEL_ID" "$DOMAIN" 2>&1 | tee "$LOG_DIR/route.log" || true
"$BIN" tunnel route dns "$TUNNEL_ID" "www.$DOMAIN" 2>&1 | tee -a "$LOG_DIR/route.log" || true

# Start tunnel
nohup "$BIN" tunnel --config "$CONFIG" run "$TUNNEL_ID" \
  >"$LOG_DIR/tunnel.log" 2>&1 &
echo $! >"$PID_DIR/tunnel.pid"
sleep 3

if pgrep -f "cloudflared tunnel" >/dev/null; then
  echo "tunnel_running pid=$(cat "$PID_DIR/tunnel.pid")"
else
  echo "tunnel_failed; see $LOG_DIR/tunnel.log" >&2
  tail -20 "$LOG_DIR/tunnel.log" >&2
  exit 3
fi

echo "done"
