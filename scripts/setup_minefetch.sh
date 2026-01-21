#!/bin/bash
# Cross-Platform Minefetch Setup Script
# Works on Linux (apt/yum/dnf) and macOS (Homebrew)
# Automatically detects OS and installs neofetch

set -e

echo "========================================="
echo "Minefetch Setup - Cross-Platform Edition"
echo "========================================="
echo ""

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

# Install neofetch on Debian/Ubuntu (apt-get)
install_neofetch_apt() {
    echo "📦 Installing neofetch using apt-get..."
    apt-get update -qq
    apt-get install -y neofetch > /dev/null 2>&1
}

# Install neofetch on RHEL/CentOS/Fedora (yum/dnf)
install_neofetch_yum() {
    echo "📦 Installing neofetch using yum/dnf..."
    if command -v dnf &> /dev/null; then
        dnf install -y neofetch > /dev/null 2>&1
    else
        yum install -y neofetch > /dev/null 2>&1
    fi
}

# Install neofetch on macOS (Homebrew)
install_neofetch_brew() {
    echo "📦 Installing neofetch using Homebrew..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Installing Homebrew first..."
        echo "This may take a few minutes..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Install neofetch
    brew install neofetch
}

# Main installation logic
OS=$(detect_os)

echo "🔍 Detected OS: $OS"
echo ""

case "$OS" in
    linux)
        # Running on Linux
        DISTRO=$(detect_linux_distro)
        echo "🐧 Linux Distribution: $DISTRO"
        echo ""
        
        case "$DISTRO" in
            ubuntu|debian)
                install_neofetch_apt
                ;;
            fedora|rhel|centos|rocky|almalinux)
                install_neofetch_yum
                ;;
            *)
                echo "❌ Unsupported Linux distribution: $DISTRO"
                echo "Please install neofetch manually:"
                echo "  Ubuntu/Debian: apt-get install neofetch"
                echo "  Fedora/RHEL: dnf install neofetch"
                exit 1
                ;;
        esac
        ;;
        
    macos)
        # Running on macOS
        echo "🍎 macOS detected"
        echo ""
        install_neofetch_brew
        ;;
        
    *)
        echo "❌ Unsupported operating system: $OSTYPE"
        echo "This script supports Linux and macOS only."
        exit 1
        ;;
esac

# Verify installation
echo ""
echo "✅ Verifying neofetch installation..."
if command -v neofetch &> /dev/null; then
    NEOFETCH_VERSION=$(neofetch --version 2>&1 | head -1)
    echo "✓ Neofetch installed successfully: $NEOFETCH_VERSION"
    echo ""
    echo "========================================="
    echo "✨ Minefetch setup complete!"
    echo "========================================="
    echo ""
    echo "Players can now use these commands:"
    echo "  /minefetch  - Display system information"
    echo "  /loadfetch  - Display CPU/RAM usage graphs"
    echo ""
    echo "Testing neofetch output:"
    echo "========================================="
    neofetch --off --stdout | head -10
    echo "========================================="
else
    echo "❌ Failed to install neofetch"
    echo "Please install manually and try again"
    exit 1
fi
