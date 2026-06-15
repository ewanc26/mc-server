#!/bin/bash

# Auto-Configuration Script for Minecraft Server
# Automatically selects optimal Java version and plugin versions based on MC version

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get Minecraft version from environment or use default
MC_VERSION="${MC_VERSION:-1.21.1}"

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

# Extract major.minor version
MC_MAJOR_MINOR=$(echo "$MC_VERSION" | grep -oE '^[0-9]+\.[0-9]+')

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

# Determine compatible plugin versions
echo -e "${GREEN}[AUTO-CONFIG]${NC} Selecting compatible plugins..."

# Latest stable versions for 1.21.1
VIAVERSION_URL="https://github.com/ViaVersion/ViaVersion/releases/download/5.9.1/ViaVersion-5.9.1.jar"
BACKUPER_URL="https://github.com/DVDishka/Backuper/releases/download/4.0.6/Backuper-4.0.6.jar"
MINEFETCH_URL="https://github.com/mlijekome/minefetch/releases/download/Release/Minefetch-1.0-SNAPSHOT.jar"
LUCKPERMS_URL="https://download.luckperms.net/1554/bukkit/loader/LuckPerms-Bukkit-5.4.151.jar"
SPARK_URL="https://spark.lucko.me/download/bukkit/spark-1.10.117.jar"

# Combine plugin URLs
PLUGINS="${BACKUPER_URL},${VIAVERSION_URL},${MINEFETCH_URL},${LUCKPERMS_URL},${SPARK_URL}"

# Generate/update .env file
ENV_FILE="$(dirname "$0")/../.env"

echo -e "${GREEN}[AUTO-CONFIG]${NC} Updating .env file with optimal settings..."

# Create or update .env file
cat > "$ENV_FILE" << EOF
# Auto-generated configuration for Minecraft ${MC_VERSION}
# Generated on: $(date)

# Optimal Java version for Minecraft ${MC_VERSION}
MC_IMAGE_TAG=${JAVA_VERSION}

# Minecraft server version
MC_VERSION=${MC_VERSION}

# Auto-selected compatible plugins
MC_PLUGINS=${PLUGINS}

# JVM Options (optimized for ${JAVA_VERSION})
EOF

# Add Java-version-specific JVM flags
if [ "$JAVA_VERSION" = "java21" ] || [ "$JAVA_VERSION" = "java17" ]; then
    cat >> "$ENV_FILE" << 'EOF'
MC_JVM_OPTS=-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:+UseStringDeduplication
EOF
else
    # Older Java versions include biased locking
    cat >> "$ENV_FILE" << 'EOF'
MC_JVM_OPTS=-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:-UseBiasedLocking -XX:+UseStringDeduplication
EOF
fi

# Add memory settings if not already set
if ! grep -q "MC_INIT_MEMORY" "$ENV_FILE" 2>/dev/null || [ "$1" = "--reset-memory" ]; then
    cat >> "$ENV_FILE" << 'EOF'

# Memory settings (Maximum Efficiency)
MC_INIT_MEMORY=256M
MC_MAX_MEMORY=1280M
MC_VIEW_DISTANCE=4
MC_SIMULATION_DISTANCE=3
MC_MAX_PLAYERS=6
EOF
fi

echo -e "${GREEN}[SUCCESS]${NC} Configuration complete!"
echo ""
echo -e "Configuration summary:"
echo -e "  Minecraft Version: ${YELLOW}${MC_VERSION}${NC}"
echo -e "  Java Version:      ${YELLOW}${JAVA_VERSION}${NC}"
echo -e "  Plugins:           ViaVersion, Backuper, Minefetch, LuckPerms, Spark"
echo ""
echo -e "To use a different Minecraft version, run:"
echo -e "  ${YELLOW}MC_VERSION=1.20.4 $0${NC}"
echo ""
echo -e "Configuration saved to: ${ENV_FILE}"
