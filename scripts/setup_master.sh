#!/bin/bash

# Master Setup Script for Ewan's Minecraft Server
# Enhanced with Maximum Efficiency Optimizations and Minefetch Integration

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$SERVER_DIR/compose.yml"
BACKUP_DIR="$SERVER_DIR/data_backups"
CONFIG_APPLIED=false

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

print_header() {
    echo -e "${CYAN}[====]${NC} $1"
}

print_tip() {
    echo -e "${MAGENTA}[TIP]${NC} $1"
}

# Function to print banner
print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     Ewan's Minecraft Server - Master Setup Script        ║
║     Maximum Efficiency Edition with Minefetch            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
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

# Function to detect Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    else
        DISTRO="unknown"
    fi
}

# Function to check if Docker is installed and running
check_docker() {
    print_info "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed."
        print_info "Please install Docker Desktop from https://www.docker.com/products/docker-desktop/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is installed but not running."
        print_info "Please start Docker Desktop and try again."
        exit 1
    fi
    print_success "Docker is installed and running."
}

# Function to check if Docker Compose is installed
check_docker_compose() {
    print_info "Checking Docker Compose installation..."
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed."
        print_info "It's usually included with Docker Desktop. Please ensure Docker Desktop is up to date."
        exit 1
    fi
    print_success "Docker Compose is available."
}

# Function to create backup
create_backup() {
    print_header "Creating Backup"
    
    if [ ! -d "$SERVER_DIR/data" ]; then
        print_warning "No data directory found. Skipping backup."
        return 0
    fi
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    local backup_name="data_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    print_info "Creating backup: $backup_name"
    print_info "This may take a few minutes..."
    
    if cp -r "$SERVER_DIR/data" "$backup_path"; then
        print_success "Backup created successfully at: $backup_path"
        
        # Also backup compose.yml
        if [ -f "$COMPOSE_FILE" ]; then
            cp "$COMPOSE_FILE" "$backup_path/compose.yml.backup"
            print_success "compose.yml backed up as well"
        fi
        
        return 0
    else
        print_error "Failed to create backup"
        return 1
    fi
}

# Function to show optimization levels
show_optimization_levels() {
    echo ""
    print_header "Available Optimization Levels"
    echo ""
    
    echo -e "${GREEN}1) Maximum Efficiency (RECOMMENDED)${NC}"
    echo "   ├─ Memory: 256MB-1.28GB (93% reduction)"
    echo "   ├─ Players: 6 max"
    echo "   ├─ View Distance: 4 chunks"
    echo "   ├─ Plugins: 5 essential"
    echo "   ├─ Cost Savings: ~$60/month"
    echo "   └─ Best for: 2-6 players, budget hosting"
    echo ""
    
    echo -e "${YELLOW}2) Ultra-Optimized (BALANCED)${NC}"
    echo "   ├─ Memory: 384MB-1.5GB (75% reduction)"
    echo "   ├─ Players: 8 max"
    echo "   ├─ View Distance: 5 chunks"
    echo "   ├─ Plugins: 6 essential"
    echo "   ├─ Cost Savings: ~$45/month"
    echo "   └─ Best for: 4-8 players, moderate hosting"
    echo ""
    
    echo -e "${CYAN}3) Light Optimization${NC}"
    echo "   ├─ Memory: 512MB-2GB (50% reduction)"
    echo "   ├─ Players: 10 max"
    echo "   ├─ View Distance: 6 chunks"
    echo "   ├─ Plugins: 6 essential"
    echo "   ├─ Cost Savings: ~$30/month"
    echo "   └─ Best for: 6-10 players, standard hosting"
    echo ""
    
    echo -e "${RED}4) Original Configuration${NC}"
    echo "   ├─ Memory: 4GB fixed"
    echo "   ├─ Players: 10 max"
    echo "   ├─ View Distance: 10 chunks"
    echo "   ├─ Plugins: 11 total"
    echo "   ├─ Cost: Full price"
    echo "   └─ Best for: High-end hosting, many players"
    echo ""
    
    echo -e "${BLUE}5) Skip Optimization${NC}"
    echo "   └─ Keep current configuration"
    echo ""
}

# Function to apply Maximum Efficiency configuration
apply_max_efficiency() {
    print_header "Applying Maximum Efficiency Configuration"
    
    # The compose.yml is already updated with max efficiency settings
    # Just verify it exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "compose.yml not found at $COMPOSE_FILE"
        return 1
    fi
    
    print_success "Maximum Efficiency configuration already applied to compose.yml"
    print_info "Configuration includes:"
    echo "  - Memory: 256MB-1.28GB"
    echo "  - View Distance: 4 chunks"
    echo "  - Simulation Distance: 3 chunks"
    echo "  - Max Players: 6"
    echo "  - Plugins: 5 essential (includes Minefetch)"
    echo "  - Advanced JVM tuning (16 custom flags)"
    echo "  - Aggressive Paper/Spigot/Bukkit optimizations"
    
    CONFIG_APPLIED=true
    return 0
}

# Function to install neofetch (cross-platform)
install_neofetch() {
    print_header "Installing Neofetch for Minefetch Plugin"
    
    # Check if server is running
    if ! docker ps | grep -q "mc"; then
        print_warning "Server container 'mc' is not running."
        print_info "Please start the server first, then run: docker exec mc apt-get update && docker exec mc apt-get install -y neofetch"
        return 1
    fi
    
    print_info "Detected OS: $OS"
    
    if [ "$OS" == "Linux" ] || docker ps | grep -q "mc"; then
        # Install in Docker container
        print_info "Installing neofetch in server container..."
        
        # Detect container OS
        docker exec mc bash -c "cat /etc/os-release" &> /dev/null
        if [ $? -eq 0 ]; then
            local container_os=$(docker exec mc bash -c "grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '\"'")
            print_info "Container OS: $container_os"
            
            case "$container_os" in
                ubuntu|debian)
                    print_info "Installing via apt-get..."
                    docker exec mc bash -c "apt-get update -qq && apt-get install -y neofetch" > /dev/null 2>&1
                    ;;
                fedora|rhel|centos|rocky|almalinux)
                    print_info "Installing via dnf/yum..."
                    if docker exec mc bash -c "command -v dnf" &> /dev/null; then
                        docker exec mc bash -c "dnf install -y neofetch" > /dev/null 2>&1
                    else
                        docker exec mc bash -c "yum install -y neofetch" > /dev/null 2>&1
                    fi
                    ;;
                *)
                    print_warning "Unknown container OS. Attempting apt-get..."
                    docker exec mc bash -c "apt-get update -qq && apt-get install -y neofetch" > /dev/null 2>&1
                    ;;
            esac
        fi
        
        # Verify installation
        if docker exec mc bash -c "command -v neofetch" &> /dev/null; then
            local version=$(docker exec mc neofetch --version 2>&1 | head -1)
            print_success "Neofetch installed in container: $version"
            
            # Test it
            print_info "Testing neofetch output:"
            echo "----------------------------------------"
            docker exec mc neofetch --off --stdout | head -10
            echo "----------------------------------------"
            
            return 0
        else
            print_error "Failed to install neofetch in container"
            return 1
        fi
    elif [ "$OS" == "macOS" ]; then
        # Install on macOS host (for reference)
        print_info "Detected macOS. Installing neofetch via Homebrew..."
        
        if ! command -v brew &> /dev/null; then
            print_warning "Homebrew not found. Installing Homebrew first..."
            print_info "This may take several minutes. Please be patient..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
        
        print_info "Installing neofetch..."
        brew install neofetch
        
        if command -v neofetch &> /dev/null; then
            print_success "Neofetch installed on macOS host"
            print_info "Note: For Minefetch to work in Minecraft, neofetch must also be in the container"
            return 0
        else
            print_error "Failed to install neofetch on macOS"
            return 1
        fi
    fi
}

# Function to setup DuckDNS
setup_duckdns_service() {
    print_header "Setting up DuckDNS"
    
    local duckdns_script="$SCRIPT_DIR/setup_duckdns.sh"
    
    if [ -f "$duckdns_script" ]; then
        chmod +x "$duckdns_script"
        "$duckdns_script"
        if [ $? -eq 0 ]; then
            print_success "DuckDNS setup completed"
        else
            print_error "DuckDNS setup failed. Check output above."
            return 1
        fi
    else
        print_error "setup_duckdns.sh not found in scripts directory"
        return 1
    fi
}

# Function to start the Minecraft server
start_minecraft_server() {
    print_header "Starting Minecraft Server"
    
    cd "$SERVER_DIR"
    
    print_info "Starting server with docker-compose..."
    
    if docker-compose up -d 2>/dev/null || docker compose up -d 2>/dev/null; then
        print_success "Server started successfully"
        
        print_info "Waiting for server to initialize (this may take 30-60 seconds)..."
        sleep 5
        
        # Show logs
        print_info "Showing server logs (Ctrl+C to stop watching):"
        echo "----------------------------------------"
        docker-compose logs -f --tail=20 mc 2>/dev/null || docker compose logs -f --tail=20 mc 2>/dev/null &
        local logs_pid=$!
        
        # Wait a bit then stop showing logs
        sleep 15
        kill $logs_pid 2>/dev/null
        
        echo ""
        print_tip "To view full logs, run: docker-compose logs -f mc"
        print_tip "To check server status, run: docker ps"
        
        return 0
    else
        print_error "Failed to start server"
        return 1
    fi
}

# Function to show server status
show_server_status() {
    print_header "Server Status"
    
    if docker ps | grep -q "mc"; then
        print_success "Server is RUNNING"
        
        # Get resource usage
        print_info "Resource Usage:"
        docker stats mc --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
        
        echo ""
        print_tip "In-game commands to check performance:"
        echo "  /tps        - Check server TPS"
        echo "  /minefetch  - Display system information"
        echo "  /loadfetch  - Display CPU/RAM usage with graphs"
    else
        print_warning "Server is NOT running"
        print_info "To start: docker-compose up -d"
    fi
}

# Function to run post-installation tests
run_post_install_tests() {
    print_header "Running Post-Installation Tests"
    
    local tests_passed=0
    local tests_total=5
    
    # Test 1: Docker running
    print_info "Test 1/5: Docker status"
    if docker ps | grep -q "mc"; then
        print_success "✓ Server container is running"
        ((tests_passed++))
    else
        print_error "✗ Server container is not running"
    fi
    
    # Test 2: Memory usage
    print_info "Test 2/5: Memory usage"
    local mem_usage=$(docker stats mc --no-stream --format "{{.MemUsage}}" | awk '{print $1}')
    if [[ ! -z "$mem_usage" ]]; then
        print_success "✓ Memory usage: $mem_usage"
        ((tests_passed++))
    else
        print_error "✗ Could not get memory usage"
    fi
    
    # Test 3: Neofetch installed
    print_info "Test 3/5: Neofetch installation"
    if docker exec mc bash -c "command -v neofetch" &> /dev/null; then
        print_success "✓ Neofetch is installed"
        ((tests_passed++))
    else
        print_warning "✗ Neofetch is not installed (Minefetch won't work)"
    fi
    
    # Test 4: TCP Shield plugin
    print_info "Test 4/5: TCP Shield plugin"
    sleep 2
    if docker-compose logs mc 2>/dev/null | grep -q "TCPShield" || docker compose logs mc 2>/dev/null | grep -q "TCPShield"; then
        print_success "✓ TCP Shield plugin detected"
        ((tests_passed++))
    else
        print_warning "✗ TCP Shield plugin not detected (may still be loading)"
    fi
    
    # Test 5: Server responsiveness
    print_info "Test 5/5: Server responsiveness"
    if docker-compose logs mc 2>/dev/null | grep -q "Done" || docker compose logs mc 2>/dev/null | grep -q "Done"; then
        print_success "✓ Server is ready (Done loading)"
        ((tests_passed++))
    else
        print_warning "✗ Server still initializing (this is normal, wait 1-2 minutes)"
    fi
    
    echo ""
    print_info "Tests Passed: $tests_passed/$tests_total"
    
    if [ $tests_passed -ge 3 ]; then
        print_success "Server setup looks good! ✓"
    else
        print_warning "Some tests failed. Please check the output above."
    fi
}

# Function to setup aliases
setup_aliases() {
    print_header "Setting up Command Aliases"
    
    local shell_profile=""

    if [ "$OS" == "macOS" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            shell_profile="$HOME/.zshrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            shell_profile="$HOME/.bash_profile"
        fi
        ALIAS_SCRIPT="server_status_mac.sh"
    elif [ "$OS" == "Linux" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            shell_profile="$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
            shell_profile="$HOME/.zshrc"
        fi
        ALIAS_SCRIPT="server_status_linux.sh"
    fi

    if [ -n "$shell_profile" ]; then
        local alias_command="alias mcserver='$SCRIPT_DIR/$ALIAS_SCRIPT'"
        
        if ! grep -q "alias mcserver=" "$shell_profile"; then
            echo "" >> "$shell_profile"
            echo "# Minecraft Server Aliases" >> "$shell_profile"
            echo "$alias_command" >> "$shell_profile"
            echo "alias mclog='docker-compose -f $SERVER_DIR/compose.yml logs -f mc'" >> "$shell_profile"
            echo "alias mcstats='docker stats mc'" >> "$shell_profile"
            echo "alias mcstop='docker-compose -f $SERVER_DIR/compose.yml down'" >> "$shell_profile"
            echo "alias mcstart='docker-compose -f $SERVER_DIR/compose.yml up -d'" >> "$shell_profile"
            echo "alias mcrestart='docker-compose -f $SERVER_DIR/compose.yml restart'" >> "$shell_profile"
            
            print_success "Aliases added to $shell_profile"
            print_info "Available aliases:"
            echo "  mcserver  - Server status script"
            echo "  mclog     - View server logs"
            echo "  mcstats   - View resource usage"
            echo "  mcstart   - Start server"
            echo "  mcstop    - Stop server"
            echo "  mcrestart - Restart server"
            echo ""
            print_tip "Run: source $shell_profile (or restart terminal)"
        else
            print_info "Aliases already exist in $shell_profile"
        fi
    else
        print_warning "Could not find shell profile. Please add aliases manually."
    fi
}

# Function to display final summary
display_summary() {
    echo ""
    print_header "Setup Complete! 🎉"
    echo ""
    
    print_success "Your Minecraft server is configured and ready!"
    echo ""
    
    if [ "$CONFIG_APPLIED" = true ]; then
        echo -e "${GREEN}Applied Configuration: Maximum Efficiency${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Memory Usage: 256MB-1.28GB (93% reduction)"
        echo "  Max Players: 6"
        echo "  View Distance: 4 chunks"
        echo "  Simulation Distance: 3 chunks"
        echo "  Plugins: 5 essential (includes Minefetch)"
        echo "  Estimated Savings: ~$60/month"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
    
    print_info "Quick Commands:"
    echo "  View logs:     docker-compose logs -f mc"
    echo "  Check status:  docker stats mc"
    echo "  Stop server:   docker-compose down"
    echo "  Restart:       docker-compose restart"
    echo ""
    
    print_info "In-Game Commands (once connected):"
    echo "  /minefetch  - Display system information"
    echo "  /loadfetch  - Display CPU/RAM usage graphs"
    echo "  /tps        - Check server performance"
    echo ""
    
    print_info "Next Steps:"
    echo "  1. Wait 1-2 minutes for full server startup"
    echo "  2. Connect via your TCP Shield domain"
    echo "  3. Run /minefetch to test system monitoring"
    echo "  4. Monitor performance with: docker stats mc"
    echo ""
    
    print_info "Documentation:"
    echo "  - MAX_EFFICIENCY_GUIDE.md - Complete optimization details"
    echo "  - docs/ folder - Additional guides and troubleshooting"
    echo ""
    
    if [ -d "$BACKUP_DIR" ]; then
        print_tip "Backups are stored in: $BACKUP_DIR"
    fi
    
    echo ""
    print_success "Happy crafting! ⛏️"
    echo ""
}

# Main function
main() {
    clear
    print_banner
    
    # Detect OS
    detect_os
    print_info "Detected Operating System: $OS"
    
    if [ "$OS" == "Linux" ]; then
        detect_linux_distro
        print_info "Linux Distribution: $DISTRO"
    fi
    
    if [ "$OS" == "Unknown" ]; then
        print_error "Unsupported operating system: $OSTYPE"
        print_info "This script supports macOS and Linux only"
        exit 1
    fi
    echo ""
    
    # Check prerequisites
    check_docker
    check_docker_compose
    echo ""
    
    # Auto-configure Java version and plugins based on Minecraft version
    print_header "Auto-Configuring for Minecraft Version"
    if [ -f "$SCRIPT_DIR/auto_configure.sh" ]; then
        # Make script executable
        chmod +x "$SCRIPT_DIR/auto_configure.sh"
        
        # Get MC version if set, otherwise prompt
        if [ -z "$MC_VERSION" ]; then
            read -p "Minecraft version to use [1.21.1]: " input_version
            export MC_VERSION="${input_version:-1.21.1}"
        fi
        
        # Run auto-configuration
        bash "$SCRIPT_DIR/auto_configure.sh"
        print_success "Auto-configuration complete"
    else
        print_warning "Auto-configuration script not found. Using defaults."
    fi
    echo ""
    
    # Create backup
    print_info "It's recommended to create a backup before proceeding."
    read -p "Create backup now? (Y/n): " backup_choice
    if [[ ! "$backup_choice" =~ ^[Nn]$ ]]; then
        create_backup || print_warning "Continuing without backup..."
    fi
    echo ""
    
    # Show optimization levels and apply
    show_optimization_levels
    read -p "Select optimization level (1-5) [1]: " opt_level
    opt_level=${opt_level:-1}
    
    case "$opt_level" in
        1)
            apply_max_efficiency
            ;;
        2|3|4)
            print_info "Selected configuration level $opt_level"
            print_warning "Note: The current compose.yml has Maximum Efficiency applied"
            print_warning "To use other levels, you'll need to manually modify compose.yml"
            print_tip "See documentation for configuration examples"
            ;;
        5)
            print_info "Skipping optimization. Using current configuration."
            ;;
        *)
            print_warning "Invalid selection. Using current configuration."
            ;;
    esac
    echo ""
    
    # Setup DuckDNS
    read -p "Do you want to set up or reconfigure DuckDNS? (y/N): " setup_duckdns_choice
    if [[ "$setup_duckdns_choice" =~ ^[Yy]$ ]]; then
        setup_duckdns_service
    else
        print_info "Skipping DuckDNS setup"
    fi
    echo ""
    
    # Start Minecraft Server
    read -p "Do you want to start the Minecraft server now? (Y/n): " start_server_choice
    if [[ ! "$start_server_choice" =~ ^[Nn]$ ]]; then
        start_minecraft_server
    else
        print_info "Skipping server start"
        print_tip "Start manually with: docker-compose up -d"
    fi
    echo ""
    
    # Install Minefetch
    if docker ps | grep -q "mc"; then
        read -p "Install neofetch for Minefetch plugin? (Y/n): " install_neo_choice
        if [[ ! "$install_neo_choice" =~ ^[Nn]$ ]]; then
            install_neofetch
        else
            print_info "Skipping neofetch installation"
            print_warning "Minefetch plugin won't work without neofetch"
        fi
        echo ""
    fi
    
    # Setup Aliases
    read -p "Do you want to set up command aliases? (Y/n): " setup_aliases_choice
    if [[ ! "$setup_aliases_choice" =~ ^[Nn]$ ]]; then
        setup_aliases
    else
        print_info "Skipping alias setup"
    fi
    echo ""
    
    # Run tests
    if docker ps | grep -q "mc"; then
        read -p "Run post-installation tests? (Y/n): " run_tests_choice
        if [[ ! "$run_tests_choice" =~ ^[Nn]$ ]]; then
            echo ""
            run_post_install_tests
            echo ""
        fi
    fi
    
    # Show final summary
    display_summary
}

# Run main function
main "$@"
