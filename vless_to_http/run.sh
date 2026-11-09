#!/bin/sh
# Home Assistant add-on wrapper for the upstream VLESS-to-HTTP entrypoint.
# Reads /data/options.json, writes a vless.conf and starts Xray on port 8181.
set -eu

OPTIONS_FILE="${OPTIONS_FILE:-/data/options.json}"
CONF="${VLESS_CONF:-/tmp/vless.conf}"
export VLESS_CONF="$CONF"

# Fixed listen ports inside the container. 8181 replaces upstream's 8080.
export LISTEN_ADDR="0.0.0.0"
export HTTP_LISTEN_PORT="8181"
export SOCKS_LISTEN_PORT="1080"

LOG_LEVEL="warning"
PROXY_USER=""
PROXY_PASS=""
PRINT_CONFIG="0"
FAILOVER_STRATEGY="leastPing"
PROBE_URL="https://www.gstatic.com/generate_204"
PROBE_INTERVAL="1m"
BYPASS_JSON="[]"

if [ -f "$OPTIONS_FILE" ]; then
  LOG_LEVEL="$(jq -r '.log_level // "warning"' "$OPTIONS_FILE")"
  PROXY_USER="$(jq -r '.proxy_user // ""' "$OPTIONS_FILE")"
  PROXY_PASS="$(jq -r '.proxy_pass // ""' "$OPTIONS_FILE")"
  FAILOVER_STRATEGY="$(jq -r '.failover_strategy // "leastPing"' "$OPTIONS_FILE")"
  PROBE_URL="$(jq -r '.probe_url // "https://www.gstatic.com/generate_204"' "$OPTIONS_FILE")"
  PROBE_INTERVAL="$(jq -r '.probe_interval // "1m"' "$OPTIONS_FILE")"
  BYPASS_JSON="$(jq -c '(.bypass_list // [])' "$OPTIONS_FILE")"
  if [ "$(jq -r 'if .print_config then "1" else "0" end' "$OPTIONS_FILE")" = "1" ]; then
    PRINT_CONFIG="1"
  fi
  jq -r '(.vless_links // [])[]' "$OPTIONS_FILE" > "$CONF" || : > "$CONF"
else
  : > "$CONF"
fi

if ! grep -q 'vless://' "$CONF"; then
  echo "ERR: no VLESS link configured." >&2
  echo "Open Settings > Add-ons > VLESS to HTTP > Configuration and add at least one" >&2
  echo "vless:// URL to the 'vless_links' list, then start the add-on." >&2
  exit 23
fi

chmod 644 "$CONF" 2>/dev/null || true

export LOG_LEVEL PROXY_USER PROXY_PASS PRINT_CONFIG FAILOVER_STRATEGY PROBE_URL PROBE_INTERVAL
export BYPASS_JSON
export XRAY_BIN="/app/xray-wrapper.sh"

exec /app/entrypoint.sh
