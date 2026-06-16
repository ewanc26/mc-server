#!/usr/bin/env bash
# sync_from_server.sh
# Reads live server JSON files (whitelist, ops, bans) and syncs config back
# into .env (runtime) and compose.yml defaults (git-tracked).
#
# Usage:
#   ./scripts/sync_from_server.sh [options]
#
# Options:
#   --commit                 git add compose.yml && git commit after sync
#   --message <msg>          custom commit message (implies --commit)
#   --dry-run                preview changes without writing any files
#   --remote <user@host>     pull JSON files from a remote host via scp
#   --remote-path <path>     data dir on the remote host (defaults to local MC_DATA_DIR)
#   --bans                   also sync banned-players.json and banned-ips.json
#   --help                   show this help

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
COMPOSE_FILE="$REPO_ROOT/compose.yml"
MANIFEST_FILE="$REPO_ROOT/sync-manifest.json"

# ── Colour palette (matches auto_configure.sh) ───────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${GREEN}[SYNC]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
err()     { echo -e "${RED}[ERROR]${NC} $*" >&2; }
section() { echo -e "\n${BOLD}${CYAN}── $* ──${NC}"; }

# ── Defaults ─────────────────────────────────────────────────────────────────
DO_COMMIT=false
DO_DRY_RUN=false
DO_BANS=false
COMMIT_MSG=""
REMOTE_HOST=""
REMOTE_PATH=""
TMPDIR_REMOTE=""

# ── Argument parsing ──────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --commit                 git add compose.yml && git commit after sync
  --message <msg>          custom commit message (implies --commit)
  --dry-run                preview changes without writing any files
  --remote <user@host>     pull JSON files from a remote host via scp
  --remote-path <path>     data dir on the remote host (defaults to local MC_DATA_DIR)
  --bans                   also sync banned-players.json and banned-ips.json
  --help                   show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit)       DO_COMMIT=true ;;
    --dry-run)      DO_DRY_RUN=true ;;
    --bans)         DO_BANS=true ;;
    --message)      COMMIT_MSG="$2"; DO_COMMIT=true; shift ;;
    --remote)       REMOTE_HOST="$2"; shift ;;
    --remote-path)  REMOTE_PATH="$2"; shift ;;
    --help|-h)      usage; exit 0 ;;
    *)              err "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

# ── Dependency check ──────────────────────────────────────────────────────────
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    err "'$1' not found — install it and try again."
    exit 1
  fi
}

check_dep jq
check_dep python3
[[ -n "$REMOTE_HOST" ]] && check_dep scp

# ── Resolve data dir ──────────────────────────────────────────────────────────
DATA_DIR=""
if [[ -f "$ENV_FILE" ]]; then
  DATA_DIR="$(grep -E '^MC_DATA_DIR=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' || true)"
fi
DATA_DIR="${DATA_DIR:-/Volumes/Storage/Server/MC/data}"

# ── Remote: pull JSON via scp ─────────────────────────────────────────────────
if [[ -n "$REMOTE_HOST" ]]; then
  REMOTE_PATH="${REMOTE_PATH:-$DATA_DIR}"
  TMPDIR_REMOTE="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR_REMOTE"' EXIT

  section "Fetching from ${BOLD}$REMOTE_HOST${NC}${CYAN}:$REMOTE_PATH"

  FILES_TO_FETCH=(whitelist.json ops.json)
  $DO_BANS && FILES_TO_FETCH+=(banned-players.json banned-ips.json)

  for f in "${FILES_TO_FETCH[@]}"; do
    if scp -q "$REMOTE_HOST:$REMOTE_PATH/$f" "$TMPDIR_REMOTE/$f" 2>/dev/null; then
      info "Fetched $f"
    else
      warn "Could not fetch $f — will skip"
    fi
  done

  DATA_DIR="$TMPDIR_REMOTE"
fi

# ── Helpers: extract & display ────────────────────────────────────────────────

# Returns a comma-separated UUID string from a JSON array with .uuid fields
extract_uuids() {
  local file="$1"
  [[ -f "$file" ]] || { echo ""; return; }
  jq -r '.[].uuid' "$file" 2>/dev/null | paste -sd ',' -
}

# Returns a comma-separated IP string from banned-ips.json
extract_ips() {
  local file="$1"
  [[ -f "$file" ]] || { echo ""; return; }
  jq -r '.[].ip' "$file" 2>/dev/null | paste -sd ',' -
}

# Pretty-print entries with names + UUIDs, indented
display_player_entries() {
  local file="$1"
  [[ -f "$file" ]] || return
  jq -r '.[] | "    \(.name // "unknown") — \(.uuid)"' "$file" 2>/dev/null || true
}

display_ip_entries() {
  local file="$1"
  [[ -f "$file" ]] || return
  jq -r '.[] | "    \(.ip) — \(.reason) (expires: \(.expires))"' "$file" 2>/dev/null || true
}

# Warn on any UUID that doesn't look like a UUID
validate_uuids() {
  local csv="$1"
  local uuid_re='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  IFS=',' read -ra uuids <<< "$csv"
  for u in "${uuids[@]}"; do
    if ! echo "$u" | grep -qiE "$uuid_re"; then
      warn "Malformed UUID: $u"
    fi
  done
}

# ── File update helpers ───────────────────────────────────────────────────────

# Portable .env key=value update (Python avoids macOS/GNU sed -i divergence)
update_env_var() {
  local key="$1" value="$2" file="$3"

  if $DO_DRY_RUN; then
    local current
    current="$(grep -E "^${key}=" "$file" 2>/dev/null | cut -d= -f2- || echo "(not set)")"
    if [[ "$current" != "$value" ]]; then
      echo -e "    ${YELLOW}~${NC} ${BOLD}${key}${NC}: would update"
    else
      echo -e "    ${GREEN}✓${NC} ${BOLD}${key}${NC}: unchanged"
    fi
    return
  fi

  python3 - "$file" "$key" "$value" <<'PYEOF'
import sys, os

path, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
new_line = f"{key}={value}\n"

if os.path.exists(path):
    with open(path) as f:
        lines = f.readlines()
    found = False
    new_lines = []
    for line in lines:
        if line.startswith(f"{key}="):
            new_lines.append(new_line)
            found = True
        else:
            new_lines.append(line)
    if not found:
        new_lines.append(new_line)
    with open(path, "w") as f:
        f.writelines(new_lines)
else:
    with open(path, "w") as f:
        f.write(new_line)
PYEOF
}

# Update a ${KEY:-default} value inside compose.yml
update_compose_default() {
  local key="$1" value="$2"

  python3 - "$COMPOSE_FILE" "$key" "$value" "$DO_DRY_RUN" <<'PYEOF'
import sys, re

path, key, value, dry_run = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "true"

with open(path) as f:
    content = f.read()

pattern = re.compile(r'(\$\{' + re.escape(key) + r':-)[^}]*(})')
match = pattern.search(content)

if not match:
    print(f"  (no {key} default in compose.yml — skipping)", file=sys.stderr)
    sys.exit(0)

current_val = match.group(0)[len(f"${{{key}:-"):-1]
new_content = pattern.sub(r'\g<1>' + value + r'\2', content)

if dry_run:
    if current_val != value:
        print(f"    ~ {key} (compose default): would update")
    else:
        print(f"    ✓ {key} (compose default): unchanged")
    sys.exit(0)

if new_content == content:
    print(f"  (no {key} default in compose.yml — skipping)", file=sys.stderr)
else:
    with open(path, 'w') as f:
        f.write(new_content)
    print(f"  Updated {key} default in compose.yml")
PYEOF
}

# ── Sync a UUID-based list (whitelist, ops, banned-players) ──────────────────
sync_uuid_list() {
  local label="$1"     # display name
  local env_key="$2"   # e.g. MC_WHITELIST
  local json_file="$3" # path to JSON

  section "$label"

  if [[ ! -f "$json_file" ]]; then
    warn "$json_file not found — skipping."
    return
  fi

  local count
  count="$(jq 'length' "$json_file" 2>/dev/null || echo 0)"
  echo -e "  ${CYAN}${count} entr$([ "$count" -eq 1 ] && echo "y" || echo "ies")${NC}"
  display_player_entries "$json_file"
  echo ""

  local uuids
  uuids="$(extract_uuids "$json_file")"

  if [[ -z "$uuids" ]]; then
    warn "No UUIDs found in $(basename "$json_file") — skipping."
    return
  fi

  validate_uuids "$uuids"

  if $DO_DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} .env:"
    update_env_var "$env_key" "$uuids" "$ENV_FILE"
    echo -e "  ${YELLOW}[dry-run]${NC} compose.yml:"
    update_compose_default "$env_key" "$uuids"
    return
  fi

  update_env_var "$env_key" "$uuids" "$ENV_FILE"
  echo "  Updated ${env_key} in .env"
  update_compose_default "$env_key" "$uuids"
}

# ── Sync ip_list (banned-ips) ─────────────────────────────────────────────────
sync_ip_list() {
  local label="$1"     # display name
  local env_key="$2"   # e.g. MC_BANNED_IPS
  local json_file="$3" # path to JSON

  section "$label"

  if [[ ! -f "$json_file" ]]; then
    warn "$(basename "$json_file") not found — skipping."
    return
  fi

  local count
  count="$(jq 'length' "$json_file" 2>/dev/null || echo 0)"
  echo -e "  ${CYAN}${count} IP$([ "$count" -eq 1 ] && echo "" || echo "s")${NC}"
  display_ip_entries "$json_file"
  echo ""

  local ips
  ips="$(extract_ips "$json_file")"

  if [[ -z "$ips" ]]; then
    warn "No IPs found in $(basename "$json_file") — skipping."
    return
  fi

  if $DO_DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} .env:"
    update_env_var "$env_key" "$ips" "$ENV_FILE"
    echo -e "  ${YELLOW}[dry-run]${NC} compose.yml:"
    update_compose_default "$env_key" "$ips"
    return
  fi

  update_env_var "$env_key" "$ips" "$ENV_FILE"
  echo "  Updated ${env_key} in .env"
  update_compose_default "$env_key" "$ips"
}

# ── Main ──────────────────────────────────────────────────────────────────────
$DO_DRY_RUN && echo -e "\n${YELLOW}${BOLD}[DRY RUN]${NC} No files will be modified.\n"

echo -e "${BOLD}Data dir:${NC} $DATA_DIR"
[[ -n "$REMOTE_HOST" ]] && echo -e "${BOLD}Remote:${NC}   $REMOTE_HOST"

while read -r entry; do
  label=$(echo "$entry" | jq -r '.label')
  source_file=$(echo "$entry" | jq -r '.source_file')
  env_key=$(echo "$entry" | jq -r '.env_key')
  handler=$(echo "$entry" | jq -r '.handler')
  required_flag=$(echo "$entry" | jq -r '.required_flag // empty')

  if [[ -n "$required_flag" ]]; then
    [[ "$required_flag" == "bans" ]] && ! $DO_BANS && continue
  fi

  if [[ "$handler" == "uuid_list" ]]; then
    sync_uuid_list "$label" "$env_key" "$DATA_DIR/$source_file"
  elif [[ "$handler" == "ip_list" ]]; then
    sync_ip_list "$label" "$env_key" "$DATA_DIR/$source_file"
  fi
done < <(jq -c '.[]' "$MANIFEST_FILE")


# ── Optional git commit ───────────────────────────────────────────────────────
if $DO_COMMIT && ! $DO_DRY_RUN; then
  section "Git"
  cd "$REPO_ROOT"
  if git diff --quiet compose.yml; then
    info "compose.yml unchanged — nothing to commit."
  else
    : "${COMMIT_MSG:="sync: update whitelist/ops defaults from server state"}"
    git add compose.yml
    git commit -m "$COMMIT_MSG"
    info "Committed compose.yml changes."
  fi
fi

if $DO_DRY_RUN; then
  echo -e "\n${YELLOW}[DRY RUN]${NC} Done. No files were modified."
else
  echo -e "\n${GREEN}Done.${NC}"
fi

