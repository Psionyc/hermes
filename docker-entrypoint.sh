#!/usr/bin/env sh
set -eu

is_enabled() {
  case "${1:-}" in
    1|true|TRUE|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

if is_enabled "${HERMES_DASHBOARD:-}"; then
  dashboard_host="${HERMES_DASHBOARD_HOST:-0.0.0.0}"
  dashboard_port="${HERMES_DASHBOARD_PORT:-9119}"

  insecure_arg=""
  case "$dashboard_host" in
    127.0.0.1|localhost) ;;
    *) insecure_arg="--insecure" ;;
  esac

  hermes dashboard \
    --host "$dashboard_host" \
    --port "$dashboard_port" \
    --no-open \
    $insecure_arg \
    2>&1 | sed 's/^/[dashboard] /' &
fi

exec hermes "$@"
