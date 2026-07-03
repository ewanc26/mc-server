#!/bin/bash
# sysinfo-watcher.sh — Host-side file watcher for on-demand sysinfo refresh.
#
# Polls the sysinfo directory for a .refresh trigger file. When the Minefetch
# plugin creates one (triggered by a player's /minefetch command), this watcher
# deletes the trigger and regenerates host.json with fresh fastfetch output.
#
# Usage:
#   ./scripts/sysinfo-watcher.sh [sysinfo-dir]
#
# The default sysinfo dir matches the MC_SYSINFO_DIR default in compose.yml.

set -euo pipefail

SYSINFO_DIR="${1:-/Volumes/Storage/Server/MC/sysinfo}"
SYSINFO_FILE="$SYSINFO_DIR/host.json"
TRIGGER_FILE="$SYSINFO_DIR/.refresh"

if ! command -v fastfetch &> /dev/null; then
    echo "Error: fastfetch not found. Install it with: brew install fastfetch"
    exit 1
fi

echo "Watching $SYSINFO_DIR for .refresh triggers..."

while true; do
    if [ -f "$TRIGGER_FILE" ]; then
        rm -f "$TRIGGER_FILE"
        fastfetch --format json > "$SYSINFO_FILE.tmp"
        mv "$SYSINFO_FILE.tmp" "$SYSINFO_FILE"
    fi
    sleep 0.5
done
