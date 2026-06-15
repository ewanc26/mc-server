if ! brew list --cask orbstack > /dev/null 2>&1; then
  echo "OrbStack is not installed. Please install it with: brew install orbstack"
  # brew install orbstack
fi

# Quick Start - Run the auto-configuration
# Aikar's optimized JVM flags are now configured in compose.yml for 6GB memory.
# To start the server, ensure you have set the version and run the configuration script:
# MC_VERSION=1.21.1 ./scripts/auto_configure.sh

docker compose up -d
