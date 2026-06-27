#!/bin/bash

# Auto-Configuration Script for Minecraft Server
#
# Selects the optimal Java image and JVM flags for a given Minecraft version,
# and safely updates ONLY those keys in .env. Every other line in .env
# (PLAYIT_SECRET, RCON password, whitelist/ops, MC_MODRINTH_PROJECTS,
# MC_SPIGET_RESOURCES, etc.) is left untouched.
#
# Plugins are no longer selected by this script. compose.yml never reads the
# old MC_PLUGINS variable this script used to write — plugin selection lives
# directly in .env / .env.example via MC_MODRINTH_PROJECTS and
# MC_SPIGET_RESOURCES. Edit those directly to add or remove plugins.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MC_VERSION="${MC_VERSION:-1.21.1}"
RESET_MEMORY="${1:-}"
ENV_FILE="$(dirname "$0")/../.env"

echo -e "${GREEN}[AUTO-CONFIG]${NC} Configuring for Minecraft version: ${MC_VERSION}"

# Function to compare version numbers
version_ge() {
    # Returns 0 (true) if $1 >= $2
    printf '%s\n%s' "$2" "$1" | sort -V -C
}

version_lt() {
    # Returns 0 (true) if $1 < $2
    ! version_ge "$1" "$2"
}

# Determine optimal Java version
if version_lt "$MC_VERSION" "1.12"; then
    JAVA_VERSION="java8"
    echo -e "${YELLOW}[INFO]${NC} Minecraft < 1.12 detected → Using Java 8"
elif version_lt "$MC_VERSION" "1.17"; then
    JAVA_VERSION="java11"
    echo -e "${YELLOW}[INFO]${NC} Minecraft 1.12-1.16.4 detected → Using Java 11"
elif version_lt "$MC_VERSION" "1.18"; then
    JAVA_VERSION="java17"
    echo -e "${YELLOW}[INFO]${NC} Minecraft 1.17 detected → Using Java 17"
elif version_lt "$MC_VERSION" "1.20.5"; then
    JAVA_VERSION="java17"
    echo -e "${YELLOW}[INFO]${NC} Minecraft 1.18-1.20.4 detected → Using Java 17"
elif version_lt "$MC_VERSION" "1.22"; then
    JAVA_VERSION="java21"
    echo -e "${YELLOW}[INFO]${NC} Minecraft 1.20.5-1.21.x detected → Using Java 21 (LTS)"
else
    JAVA_VERSION="java21"
    echo -e "${YELLOW}[INFO]${NC} Minecraft 1.22+ detected → Using Java 21 (LTS)"
fi

# JVM flags (Aikar's, with the legacy biased-locking flag only on older Java)
if [ "$JAVA_VERSION" = "java21" ] || [ "$JAVA_VERSION" = "java17" ]; then
    JVM_OPTS='-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:+UseStringDeduplication'
else
    JVM_OPTS='-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:-UseBiasedLocking -XX:+UseStringDeduplication'
fi

# Set or update a single KEY=value line in $ENV_FILE in place.
# Leaves every other line in the file exactly as it was.
upsert_env() {
    local key="$1" value="$2" tmp
    tmp="$(mktemp)"
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        awk -F'=' -v k="$key" -v v="$value" '$1==k { $0 = k"="v } { print }' "$ENV_FILE" > "$tmp"
    else
        cat "$ENV_FILE" > "$tmp" 2>/dev/null || true
        printf '%s=%s\n' "$key" "$value" >> "$tmp"
    fi
    mv "$tmp" "$ENV_FILE"
}

touch "$ENV_FILE"

echo -e "${GREEN}[AUTO-CONFIG]${NC} Updating Java image, version, and JVM flags in .env..."
upsert_env "MC_IMAGE_TAG" "$JAVA_VERSION"
upsert_env "MC_VERSION" "$MC_VERSION"
upsert_env "MC_JVM_OPTS" "$JVM_OPTS"

# Seed sensible memory/perf defaults only if they're not already set —
# never overwrites values you've tuned yourself, unless --reset-memory is passed.
if ! grep -q "^MC_INIT_MEMORY=" "$ENV_FILE" 2>/dev/null || [ "$RESET_MEMORY" = "--reset-memory" ]; then
    echo -e "${GREEN}[AUTO-CONFIG]${NC} Setting memory/performance defaults..."
    upsert_env "MC_INIT_MEMORY" "256M"
    upsert_env "MC_MAX_MEMORY" "1280M"
    upsert_env "MC_VIEW_DISTANCE" "4"
    upsert_env "MC_SIMULATION_DISTANCE" "3"
    upsert_env "MC_MAX_PLAYERS" "6"
fi

echo -e "${GREEN}[SUCCESS]${NC} Configuration complete!"
echo ""
echo -e "Configuration summary:"
echo -e "  Minecraft Version: ${YELLOW}${MC_VERSION}${NC}"
echo -e "  Java Version:      ${YELLOW}${JAVA_VERSION}${NC}"
echo ""
echo -e "Plugins aren't touched by this script — manage MC_MODRINTH_PROJECTS"
echo -e "and MC_SPIGET_RESOURCES directly in .env."
echo ""
echo -e "To use a different Minecraft version, run:"
echo -e "  ${YELLOW}MC_VERSION=1.20.4 $0${NC}"
echo ""
echo -e "To reset memory/perf settings back to defaults, run:"
echo -e "  ${YELLOW}$0 --reset-memory${NC}"
echo ""
echo -e "Configuration saved to: ${ENV_FILE}"
