#!/bin/bash
# Cross-Platform Minefetch Setup Script
# Works on Linux (apt/yum/dnf) and macOS (Homebrew)
# Automatically detects OS and installs fastfetch + sysinfo watcher

set -e

echo "========================================="
echo "Minefetch Setup - Cross-Platform Edition"
echo "========================================="
echo ""

SYSINFO_DIR="${MC_SYSINFO_DIR:-/Volumes/Storage/Server/MC/sysinfo}"
MINEFETCH_DIR="${MC_MINEFETCH_DIR:-/Volumes/Storage/Developer/Git/minefetch}"
SYSINFO_CONFIG="${MC_SYSINFO_CONFIG:-$MINEFETCH_DIR/scripts/fastfetch-config.jsonc}"

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Detect Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Install fastfetch on macOS (Homebrew)
install_fastfetch_brew() {
    echo "Installing fastfetch using Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew first..."
        echo "This may take a few minutes..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    brew install fastfetch
}

# Install fastfetch on Debian/Ubuntu
install_fastfetch_apt() {
    echo "Installing fastfetch using apt-get..."
    sudo apt-get update -qq
    sudo apt-get install -y fastfetch
}

# Install fastfetch on Fedora/RHEL
install_fastfetch_yum() {
    echo "Installing fastfetch using yum/dnf..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y fastfetch
    else
        sudo yum install -y fastfetch
    fi
}

# Start the sysinfo watcher
start_watcher() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local watcher="$MINEFETCH_DIR/scripts/sysinfo-watcher.sh"
    local pid

    mkdir -p "$SYSINFO_DIR"

    pid=$(pgrep -f "sysinfo-watcher.sh" 2>/dev/null || true)
    if [ -n "$pid" ]; then
        echo "Sysinfo watcher already running (PID $pid)"
    else
        echo "Starting sysinfo watcher in background..."
        nohup bash "$watcher" "$SYSINFO_DIR" > /tmp/sysinfo-watcher.log 2>&1 &
        local new_pid=$!
        disown "$new_pid"
        echo "Sysinfo watcher started (PID $new_pid)"
    fi
}

# Main installation logic
OS=$(detect_os)
echo "Detected OS: $OS"
echo ""

case "$OS" in
    linux)
        DISTRO=$(detect_linux_distro)
        echo "Linux Distribution: $DISTRO"
        echo ""
        case "$DISTRO" in
            ubuntu|debian)
                install_fastfetch_apt
                ;;
            fedora|rhel|centos|rocky|almalinux)
                install_fastfetch_yum
                ;;
            *)
                echo "Unsupported Linux distribution: $DISTRO"
                echo "Please install fastfetch manually:"
                echo "  Ubuntu/Debian: sudo apt-get install fastfetch"
                echo "  Fedora/RHEL: sudo dnf install fastfetch"
                exit 1
                ;;
        esac
        ;;
    macos)
        echo "macOS detected"
        echo ""
        install_fastfetch_brew
        ;;
    *)
        echo "Unsupported operating system: $OSTYPE"
        echo "This script supports Linux and macOS only."
        exit 1
        ;;
esac

# Verify fastfetch
echo ""
echo "Verifying fastfetch installation..."
if command -v fastfetch &> /dev/null; then
    FF_VERSION=$(fastfetch --version 2>&1 | head -1)
    echo "fastfetch installed: $FF_VERSION"
else
    echo "Failed to install fastfetch"
    exit 1
fi

# Generate initial host.json
echo ""
echo "Generating initial host.json..."
mkdir -p "$SYSINFO_DIR"
fastfetch --config "$SYSINFO_CONFIG" --format json > "$SYSINFO_DIR/host.json.tmp"
mv "$SYSINFO_DIR/host.json.tmp" "$SYSINFO_DIR/host.json"
echo "Written to $SYSINFO_DIR/host.json"

# Start watcher
start_watcher

echo ""
echo "========================================="
echo "Minefetch setup complete!"
echo "========================================="
echo ""
echo "Players can now use:"
echo "  /minefetch  - Display fresh host + server info"
echo ""
echo "The sysinfo watcher polls for .refresh triggers"
echo "from the plugin so data is fetched on demand."
