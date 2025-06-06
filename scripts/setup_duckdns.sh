#!/bin/bash

# DuckDNS Setup Script
# This script helps set up DuckDNS updates based on the operating system.

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
    else
        OS="Unknown"
    fi
}

# Function to get user input for domain and token
get_duckdns_credentials() {
    echo
    print_info "Please enter your DuckDNS credentials:"
    
    while [[ -z "$DOMAIN" ]]; do
        read -p "Enter your DuckDNS domain (e.g., mydomain, without .duckdns.org): " DOMAIN
        if [[ -z "$DOMAIN" ]]; then
            print_warning "Domain cannot be empty. Please try again."
        fi
    done
    
    while [[ -z "$TOKEN" ]]; do
        read -p "Enter your DuckDNS token: " TOKEN
        if [[ -z "$TOKEN" ]]; then
            print_warning "Token cannot be empty. Please try again."
        fi
    done
}

# Function for macOS Homebrew setup
setup_macos_homebrew() {
    print_info "Setting up DuckDNS for macOS using Homebrew..."
    echo
    
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed. Please install Homebrew first."
        print_info "Run: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    print_info "Tapping jzelinskie/duckdns..."
    brew tap jzelinskie/duckdns || { print_error "Failed to tap jzelinskie/duckdns."; exit 1; }
    
    print_info "Installing duckdns..."
    brew install duckdns || { print_error "Failed to install duckdns."; exit 1; }

    # Ensure the config file is created before starting the service
    print_info "Creating ~/.duckdns file..."
    mkdir -p "$HOME/.duckdns"
    echo "DOMAIN=\"$DOMAIN\"" > "$HOME/.duckdns/duckdns.conf"
    echo "TOKEN=\"$TOKEN\"" >> "$HOME/.duckdns/duckdns.conf"

    print_info "Stopping any existing DuckDNS service (if running)..."
    brew services stop jzelinskie/duckdns/duckdns &>/dev/null || true # Ignore errors if service is not running

    print_info "Starting DuckDNS service with Homebrew services..."
    brew services start jzelinskie/duckdns/duckdns || { print_error "Failed to start DuckDNS service."; exit 1; }

    print_success "DuckDNS setup for macOS using Homebrew completed successfully!"
}

# Function for Linux Cron setup
setup_linux_cron() {
    print_info "Setting up DuckDNS for Linux using Cron..."
    echo
    
    if ! ps -ef | grep -q cr[o]n; then
        print_error "Cron is not running. Please install and start cron for your distribution."
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        print_error "Curl is not installed. Please install curl for your distribution."
        exit 1
    fi
    
    print_info "Creating duckdns directory and script..."
    mkdir -p "$HOME/duckdns"
    
    local script_path="$HOME/duckdns/duck.sh"
    local log_path="$HOME/duckdns/duck.log"
    
    cat > "$script_path" << EOF
#!/bin/bash
echo url=\" https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=\" | curl -k -o $log_path -K -
EOF
    
    print_info "Making duck.sh executable..."
    chmod 700 "$script_path" || { print_error "Failed to make duck.sh executable."; exit 1; }
    
    print_info "Setting up cron job..."
    (crontab -l 2>/dev/null; echo "*/5 * * * * $script_path >/dev/null 2>&1") | crontab - || { print_error "Failed to set up cron job."; exit 1; }
    
    print_info "Testing the script..."
    if bash "$script_path"; then
        print_success "DuckDNS update test successful!"
        print_info "Log content:"
        cat "$log_path"
    else
        print_error "DuckDNS update test failed. Check $log_path for details."
    fi
    
    print_success "DuckDNS setup for Linux using Cron completed successfully!"
}

# Main function
main() {
    print_info "DuckDNS Setup Script"
    echo "======================"
    echo
    
    # Detect operating system
    detect_os
    print_info "Detected OS: $OS"
    
    # Get DuckDNS credentials
    get_duckdns_credentials
    
    case "$OS" in
        "macOS")
            setup_macos_homebrew
            ;;
        "Linux")
            setup_linux_cron
            ;;
        "Unknown")
            print_error "Unsupported operating system: $OSTYPE"
            print_info "This script currently supports macOS and Linux."
            exit 1
            ;;
    esac
}

# Run main function
main "$@"