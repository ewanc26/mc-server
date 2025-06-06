#!/bin/bash

# Master Setup Script for Ewan's Minecraft Server

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

# Function to check if Docker is installed and running
check_docker() {
    print_info "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker Desktop from https://www.docker.com/products/docker-desktop/ and ensure it is running."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is installed but not running. Please start Docker Desktop."
        exit 1
    fi
    print_success "Docker is installed and running."
}

# Function to check if Docker Compose is installed
check_docker_compose() {
    print_info "Checking Docker Compose installation..."
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. It's usually included with Docker Desktop. Please ensure Docker Desktop is up to date."
        exit 1
    fi
    print_success "Docker Compose is available."
}

# Function to setup DuckDNS
setup_duckdns_service() {
    print_info "Setting up DuckDNS..."
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local duckdns_script="$script_dir/setup_duckdns.sh"
    
    if [ -f "$duckdns_script" ]; then
        chmod +x "$duckdns_script"
        "$duckdns_script"
        if [ $? -eq 0 ]; then
            print_success "DuckDNS setup script completed."
        else
            print_error "DuckDNS setup script failed. Please check the output above."
            return 1
        fi
    else
        print_error "setup_duckdns.sh not found in the scripts directory."
        return 1
    fi
}

# Function to start the Minecraft server
start_minecraft_server() {
    print_info "Starting the Minecraft server..."
    
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local server_script=""
    
    if [ "$OS" == "macOS" ]; then
        server_script="$script_dir/server_status_mac.sh"
    elif [ "$OS" == "Linux" ]; then
        server_script="$script_dir/server_status_linux.sh"
    else
        print_warning "No specific server start script for $OS. Attempting generic 'docker compose up -d'."
        (cd "$(dirname "$script_dir")" && \
        if docker compose up -d; then
            print_success "Minecraft server started with 'docker compose up -d'."
        else
            print_error "Failed to start Minecraft server with 'docker compose up -d'."
            return 1
        fi)
        return 0
    fi

    if [ -f "$server_script" ]; then
        chmod +x "$server_script"
        "$server_script" start
        if [ $? -eq 0 ]; then
            print_success "Minecraft server started successfully using $server_script."
        else
            print_error "Failed to start Minecraft server using $server_script. Check script output."
            return 1
        fi
    else
        print_error "Server status script ($server_script) not found."
        print_warning "Attempting generic 'docker compose up -d'."
        (cd "$(dirname "$script_dir")" && \
        if docker compose up -d; then
            print_success "Minecraft server started with 'docker compose up -d'."
        else
            print_error "Failed to start Minecraft server with 'docker compose up -d'."
            return 1
        fi)
    fi
}

# Function to set up aliases
setup_aliases() {
    print_info "Setting up aliases for server status scripts..."
    local shell_profile=""

    if [ "$OS" == "macOS" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            shell_profile="$HOME/.zshrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            shell_profile="$HOME/.bash_profile"
        else
            print_warning "No .zshrc or .bash_profile found. Please add aliases manually."
            return 1
        fi
        ALIAS_SCRIPT="server_status_mac.sh"
    elif [ "$OS" == "Linux" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            shell_profile="$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
            shell_profile="$HOME/.zshrc"
        else
            print_warning "No .bashrc or .zshrc found. Please add aliases manually."
            return 1
        fi
        ALIAS_SCRIPT="server_status_linux.sh"
    else
        print_warning "Unsupported OS for alias setup. Please add aliases manually."
        return 1
    fi

    if [ -n "$shell_profile" ]; then
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local alias_command="alias mcserver='$script_dir/$ALIAS_SCRIPT'"
        if ! grep -q "alias mcserver=" "$shell_profile"; then
            echo "" >> "$shell_profile"
            echo "# Alias for Minecraft server status script" >> "$shell_profile"
            echo "$alias_command" >> "$shell_profile"
            print_success "Alias 'mcserver' added to $shell_profile. Please run 'source $shell_profile' or restart your terminal."
        else
            print_info "Alias 'mcserver' already exists in $shell_profile."
        fi
    fi
}

# Main function
main() {
    echo
    print_info "==============================================="
    print_info " Ewan's Minecraft Server - Master Setup Script "
    print_info "==============================================="
    echo

    # Detect OS
    detect_os
    print_info "Detected Operating System: $OS"
    if [ "$OS" == "Unknown" ]; then
        print_error "Unsupported operating system: $OSTYPE. This script primarily supports macOS and Linux."
        exit 1
    fi
    echo

    # Check prerequisites
    check_docker
    check_docker_compose
    echo

    # Setup DuckDNS
    read -p "Do you want to set up or reconfigure DuckDNS? (y/N): " setup_duckdns_choice
    if [[ "$setup_duckdns_choice" =~ ^[Yy]$ ]]; then
        setup_duckdns_service || exit 1
    else
        print_info "Skipping DuckDNS setup."
    fi
    echo

    # Start Minecraft Server
    read -p "Do you want to start the Minecraft server now? (Y/n): " start_server_choice
    if [[ ! "$start_server_choice" =~ ^[Nn]$ ]]; then # Default to Yes
        start_minecraft_server || exit 1
    else
        print_info "Skipping Minecraft server start."
        print_info "You can start it later using 'docker compose up -d' or the OS-specific script (scripts/server_status_mac.sh or scripts/server_status_linux.sh)."
    fi
    echo

    # Setup Aliases
    read -p "Do you want to set up aliases for the server status scripts? (Y/n): " setup_aliases_choice
    if [[ ! "$setup_aliases_choice" =~ ^[Nn]$ ]]; then # Default to Yes
        setup_aliases
    else
        print_info "Skipping alias setup."
    fi
    echo

    print_success "Master setup process completed!"
    print_info "Please refer to the documentation for further usage instructions."
    echo
}

# Run main function
main "$@"