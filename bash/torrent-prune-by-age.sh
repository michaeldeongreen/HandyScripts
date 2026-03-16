#!/usr/bin/env bash
# torrent-prune-by-age
#
# Delete torrents (and their files) from a local qBittorrent instance
# when they are older than a retention threshold based on "completion_on" (Unix epoch timestamp).
#
# Assumptions (per your requirements):
#   - Host is always local: 127.0.0.1
#   - Scheme is always http
#
# Requirements:
#   - curl
#   - jq (required)

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

# Fixed assumptions
HOST="127.0.0.1"
SCHEME="http"

# Defaults
PORT="8080"
USER=""
PASS=""
RETENTION_RAW=""     # required (e.g. "30", "30d", "12h", "2w", "1m")
TEST_ONLY=false      # -t
ASSUME_YES=false     # -y
QUIET=false          # -q

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} -u <user> -p <pass> -d <retention> [options]

Required:
  -u   WebUI username
  -p   WebUI password
  -d   Retention threshold. Accepts:
         * integer days (e.g. 30)  -> treated as 30d
         * unit-suffixed values:
             12h   (hours)
             30d   (days)
             2w    (weeks)
             1m    (months, approximated as 30d)
             1y    (years, approximated as 365d)

Options:
  -P   Port (default: 8080)
  -t   Test mode: list what WOULD be deleted, but do not delete
  -y   Assume yes: do not prompt for confirmation when deleting
  -q   Quiet: reduce output
  -h   Show this help

Examples:
  ./${SCRIPT_NAME} -u admin -p 'secret' -d 14 -t
  ./${SCRIPT_NAME} -u admin -p 'secret' -d 72h -y

Notes:
  - Target is always local HTTP: http://127.0.0.1:<port>
  - Uses completion_on (wall-clock completed timestamp), not seeding_time.
EOF
}

die() { echo "ERROR: $*" >&2; echo >&2; usage >&2; exit 1; }
log() { $QUIET && return 0; echo "$@"; }

# Parse duration like: 30, 12h, 30d, 2w, 1m, 1y -> seconds
# - If only digits are provided, treat as days.
# - "m" (month) is approximated as 30d; "y" as 365d.
duration_to_seconds() {
  local raw="$1" num unit
  if [[ "$raw" =~ ^[0-9]+$ ]]; then
    num="$raw"; unit="d"
  elif [[ "$raw" =~ ^([0-9]+)([hdwmy])$ ]]; then
    num="${BASH_REMATCH[1]}"; unit="${BASH_REMATCH[2]}"
  else
    return 1
  fi

  case "$unit" in
    h) echo $(( num * 3600 )) ;;
    d) echo $(( num * 86400 )) ;;
    w) echo $(( num * 7 * 86400 )) ;;
    m) echo $(( num * 30 * 86400 )) ;;
    y) echo $(( num * 365 * 86400 )) ;;
    *) return 1 ;;
  esac
}

# Args
while getopts ":P:u:p:d:tyqh" opt; do
  case "$opt" in
    P) PORT="$OPTARG" ;;
    u) USER="$OPTARG" ;;
    p) PASS="$OPTARG" ;;
    d) RETENTION_RAW="$OPTARG" ;;
    t) TEST_ONLY=true ;;
    y) ASSUME_YES=true ;;
    q) QUIET=true ;;
    h) usage; exit 0 ;;
    :) die "Option -$OPTARG requires an argument." ;;
    \?) die "Unknown option: -$OPTARG" ;;
  esac
done

# Mandatory checks
[[ -z "$USER" ]] && die "Missing required -u <user>."
[[ -z "$PASS" ]] && die "Missing required -p <pass>."
[[ -z "$RETENTION_RAW" ]] && die "Missing required -d <retention>."
[[ "$PORT" =~ ^[0-9]+$ ]] || die "Invalid -P port '$PORT' (must be numeric)."

RETENTION_SECONDS="$(duration_to_seconds "$RETENTION_RAW" || true)"
[[ -n "${RETENTION_SECONDS:-}" ]] || die "Invalid -d value '$RETENTION_RAW'. Use e.g. 30, 12h, 30d, 2w, 1m, 1y."

command -v curl >/dev/null 2>&1 || die "curl not found. Git Bash normally includes curl."
command -v jq   >/dev/null 2>&1 || die "jq not found. Install jq (recommended) and re-run."

BASE="${SCHEME}://${HOST}:${PORT}"
COOKIE_JAR="$(mktemp -t qbt_cookie_XXXXXX.txt)"
trap 'rm -f "$COOKIE_JAR"' EXIT

NOW_EPOCH="$(date +%s)"
CUTOFF_EPOCH=$(( NOW_EPOCH - RETENTION_SECONDS ))

log "==> qBittorrent WebUI: ${BASE} (local http)"
log "==> Retention: ${RETENTION_RAW} (${RETENTION_SECONDS} seconds)"
log "==> Cutoff (completion_on <=): ${CUTOFF_EPOCH} (epoch seconds)"

# Login
log "==> Logging in..."
LOGIN_RESP="$(
  curl -sS \
    -c "$COOKIE_JAR" \
    -X POST \
    --data-urlencode "username=${USER}" \
    --data-urlencode "password=${PASS}" \
    "${BASE}/api/v2/auth/login"
)"
[[ "$LOGIN_RESP" == "Ok." ]] || die "Login failed. Response: ${LOGIN_RESP}"
log "==> Login OK"

# Fetch torrents
log "==> Fetching torrent list..."
TORRENTS_JSON="$(
  curl -sS \
    -b "$COOKIE_JAR" \
    "${BASE}/api/v2/torrents/info"
)"

# Build candidates (TSV: hash, completion_on, age_seconds, ratio, name)
CANDIDATES_TSV="$(
  echo "$TORRENTS_JSON" | jq -r \
    --argjson now "$NOW_EPOCH" \
    --argjson cutoff "$CUTOFF_EPOCH" '
      .[]
      | select((.completion_on // 0) > 0)
      | select((.completion_on // 0) <= $cutoff)
      | [
          .hash,
          (.completion_on // 0),
          ($now - (.completion_on // 0)),
          (.ratio // 0),
          (.name // "")
        ]
      | @tsv
    '
)"

if [[ -z "${CANDIDATES_TSV// }" ]]; then
  log "==> No torrents matched the retention threshold. Nothing to do."
  exit 0
fi

log "==> Torrents that match (older than retention):"
echo "$CANDIDATES_TSV" | awk -F'\t' '{
  printf("  - %s | age=%ss | ratio=%s | completion_on=%s | hash=%s\n", $5, $3, $4, $2, $1);
}'

HASHES_PIPE="$(echo "$CANDIDATES_TSV" | awk -F'\t' '{print $1}' | paste -sd'|' -)"
log "==> Hashes to delete: $HASHES_PIPE"

# Test mode
if $TEST_ONLY; then
  log "==> Test mode (-t): No deletions performed."
  exit 0
fi

# Confirm
if ! $ASSUME_YES; then
  echo
  echo "About to DELETE the torrents above AND their files."
  read -r -p "Type 'DELETE' to confirm: " CONFIRM
  [[ "$CONFIRM" == "DELETE" ]] || { log "==> Cancelled. No deletions performed."; exit 0; }
fi

# Delete torrents + files (POST)
log "==> Deleting torrents and files..."
DELETE_RESP="$(
  curl -sS \
    -b "$COOKIE_JAR" \
    -X POST \
    --data-urlencode "hashes=${HASHES_PIPE}" \
    --data-urlencode "deleteFiles=true" \
    "${BASE}/api/v2/torrents/delete"
)"
log "==> Delete request sent. Response: ${DELETE_RESP:-<empty>}"
log "==> Done."