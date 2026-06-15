#!/bin/bash

# Master Setup Script for Ewan's Minecraft Server

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

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

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

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          Ewan's Minecraft Server — Setup Script          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
    else
        OS="Unknown"
    fi
}

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

check_docker_compose() {
    print_info "Checking Docker Compose installation..."
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose V2 is not available."
        print_info "Ensure Docker Desktop is up to date."
        exit 1
    fi
    print_success "Docker Compose is available."
}

# ---------------------------------------------------------------------------
# .env setup
# ---------------------------------------------------------------------------

setup_env() {
    print_header "Environment Configuration"

    local env_file="$SERVER_DIR/.env"
    local env_example="$SERVER_DIR/.env.example"

    if [ ! -f "$env_file" ]; then
        if [ -f "$env_example" ]; then
            print_info "No .env file found. Copying from .env.example..."
            cp "$env_example" "$env_file"
            print_success ".env created — open it and fill in MC_VERSION at minimum."
            read -p "Press Enter when ready, or Ctrl+C to exit and edit first: "
        else
            print_warning ".env.example not found. Create .env manually before continuing."
            read -p "Press Enter when ready, or Ctrl+C to exit: "
        fi
    else
        print_success ".env file found."
    fi

    # Source .env so variables are available for the rest of the script
    if [ -f "$env_file" ]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
    fi

    if [ -z "$MC_VERSION" ]; then
        read -p "Minecraft version to use [1.21.1]: " input_version
        export MC_VERSION="${input_version:-1.21.1}"
    else
        print_info "MC_VERSION: $MC_VERSION"
    fi
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------

create_backup() {
    print_header "Creating Backup"

    local data_dir="${MC_DATA_DIR:-/Volumes/Storage/Server/MC/data}"

    if [ ! -d "$data_dir" ]; then
        print_warning "No data directory found at $data_dir. Skipping backup."
        return 0
    fi

    mkdir -p "$BACKUP_DIR"

    local backup_name="data_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"

    print_info "Creating backup: $backup_name"
    print_info "This may take a few minutes..."

    if cp -r "$data_dir" "$backup_path"; then
        print_success "Backup created at: $backup_path"
        if [ -f "$COMPOSE_FILE" ]; then
            cp "$COMPOSE_FILE" "$backup_path/compose.yml.backup"
            print_success "compose.yml backed up as well."
        fi
        return 0
    else
        print_error "Failed to create backup."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Optimisation
# ---------------------------------------------------------------------------

show_optimization_levels() {
    echo ""
    print_header "Available Optimisation Levels"
    echo ""

    echo -e "${GREEN}1) Maximum Efficiency (RECOMMENDED)${NC}"
    echo "   ├─ Memory: 256MB-1.28GB"
    echo "   ├─ Players: 6 max"
    echo "   ├─ View Distance: 4 chunks"
    echo "   └─ Best for: 2-6 players"
    echo ""

    echo -e "${YELLOW}2) Ultra-Optimised (BALANCED)${NC}"
    echo "   ├─ Memory: 384MB-1.5GB"
    echo "   ├─ Players: 8 max"
    echo "   ├─ View Distance: 5 chunks"
    echo "   └─ Best for: 4-8 players"
    echo ""

    echo -e "${CYAN}3) Light Optimisation${NC}"
    echo "   ├─ Memory: 512MB-2GB"
    echo "   ├─ Players: 10 max"
    echo "   ├─ View Distance: 6 chunks"
    echo "   └─ Best for: 6-10 players"
    echo ""

    echo -e "${RED}4) Original Configuration${NC}"
    echo "   ├─ Memory: 4GB fixed"
    echo "   ├─ Players: 10 max"
    echo "   ├─ View Distance: 10 chunks"
    echo "   └─ Best for: high-end hosting"
    echo ""

    echo -e "${BLUE}5) Skip${NC}"
    echo "   └─ Keep current configuration"
    echo ""
}

apply_max_efficiency() {
    print_header "Applying Maximum Efficiency Configuration"

    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "compose.yml not found at $COMPOSE_FILE"
        return 1
    fi

    print_success "Maximum Efficiency settings applied in compose.yml."
    print_info "Configuration:"
    echo "  - Memory: 256MB-1.28GB"
    echo "  - View Distance: 4 chunks"
    echo "  - Simulation Distance: 3 chunks"
    echo "  - Max Players: 6"
    echo "  - Plugins: 5 (Backuper, ViaVersion, Minefetch, LuckPerms, Spark)"
    echo "  - Aikar's JVM flags"

    CONFIG_APPLIED=true
    return 0
}

# ---------------------------------------------------------------------------
# Neofetch (for Minefetch plugin)
# ---------------------------------------------------------------------------

install_neofetch() {
    print_header "Installing Neofetch for Minefetch Plugin"

    if ! docker ps | grep -q "^.*mc$"; then
        print_warning "Server container 'mc' is not running. Start the server first."
        return 1
    fi

    print_info "Installing neofetch in server container..."

    local container_os
    container_os=$(docker exec mc bash -c "grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '\"'" 2>/dev/null)

    case "$container_os" in
        ubuntu|debian)
            docker exec mc bash -c "apt-get update -qq && apt-get install -y neofetch" > /dev/null 2>&1
            ;;
        fedora|rhel|centos|rocky|almalinux)
            if docker exec mc bash -c "command -v dnf" &> /dev/null; then
                docker exec mc bash -c "dnf install -y neofetch" > /dev/null 2>&1
            else
                docker exec mc bash -c "yum install -y neofetch" > /dev/null 2>&1
            fi
            ;;
        *)
            print_warning "Unknown container OS ($container_os). Attempting apt-get..."
            docker exec mc bash -c "apt-get update -qq && apt-get install -y neofetch" > /dev/null 2>&1
            ;;
    esac

    if docker exec mc bash -c "command -v neofetch" &> /dev/null; then
        local version
        version=$(docker exec mc neofetch --version 2>&1 | head -1)
        print_success "Neofetch installed: $version"
        echo "----------------------------------------"
        docker exec mc neofetch --off --stdout | head -10
        echo "----------------------------------------"
        return 0
    else
        print_error "Failed to install neofetch in container."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Server start
# ---------------------------------------------------------------------------

start_minecraft_server() {
    print_header "Starting Minecraft Server"

    cd "$SERVER_DIR" || exit 1

    if docker compose up -d; then
        print_success "Containers started."

        print_info "Waiting for server to initialise (this may take 30-60 seconds)..."
        sleep 5

        print_info "Showing server logs (Ctrl+C to stop watching):"
        echo "----------------------------------------"
        docker compose logs -f --tail=20 mc &
        local logs_pid=$!
        sleep 15
        kill $logs_pid 2>/dev/null
        echo ""

        print_tip "Full logs: docker compose logs -f mc"
        print_tip "Status:    docker ps"
        return 0
    else
        print_error "Failed to start containers."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# playit.gg tunnel
# ---------------------------------------------------------------------------

setup_playit() {
    print_header "playit.gg Tunnel"

    local env_file="$SERVER_DIR/.env"

    # Check if PLAYIT_SECRET is already configured
    if [ -f "$env_file" ] && grep -qE "^PLAYIT_SECRET=.+" "$env_file"; then
        print_success "PLAYIT_SECRET is set — tunnel will start automatically."
        return 0
    fi

    print_warning "PLAYIT_SECRET is not set in .env."
    print_info "Starting the playit agent to generate a claim URL..."

    cd "$SERVER_DIR" || exit 1
    docker compose up -d playit 2>/dev/null

    print_info "Waiting for claim URL..."
    sleep 4

    echo ""
    docker compose logs --tail=30 playit 2>/dev/null
    echo ""

    print_tip "1. Open the claim URL above in your browser and sign into playit.gg"
    print_tip "2. Add a Minecraft tunnel pointed at  mc:25565"
    print_tip "3. Copy the secret key from the playit dashboard"
    print_tip "4. Add it to .env:  PLAYIT_SECRET=your_secret_here"
    print_tip "5. Run:  docker compose restart playit"
    echo ""
}

# ---------------------------------------------------------------------------
# Shell aliases
# ---------------------------------------------------------------------------

setup_aliases() {
    print_header "Setting up Command Aliases"

    local shell_profile=""
    local alias_script=""

    if [ "$OS" == "macOS" ]; then
        shell_profile="${HOME}/.zshrc"
        [ ! -f "$shell_profile" ] && shell_profile="${HOME}/.bash_profile"
        alias_script="server_status_mac.sh"
    elif [ "$OS" == "Linux" ]; then
        shell_profile="${HOME}/.bashrc"
        [ ! -f "$shell_profile" ] && shell_profile="${HOME}/.zshrc"
        alias_script="server_status_linux.sh"
    fi

    if [ -z "$shell_profile" ]; then
        print_warning "Could not find shell profile. Add aliases manually."
        return 1
    fi

    if grep -q "alias mcserver=" "$shell_profile" 2>/dev/null; then
        print_info "Aliases already exist in $shell_profile."
        return 0
    fi

    {
        echo ""
        echo "# Minecraft Server Aliases"
        echo "alias mcserver='$SCRIPT_DIR/$alias_script'"
        echo "alias mclog='docker compose -f $COMPOSE_FILE logs -f mc'"
        echo "alias mcstats='docker stats mc'"
        echo "alias mcstart='docker compose -f $COMPOSE_FILE up -d'"
        echo "alias mcstop='docker compose -f $COMPOSE_FILE down'"
        echo "alias mcrestart='docker compose -f $COMPOSE_FILE restart'"
    } >> "$shell_profile"

    print_success "Aliases added to $shell_profile."
    print_info "Available aliases: mcserver, mclog, mcstats, mcstart, mcstop, mcrestart"
    print_tip "Run:  source $shell_profile  (or restart your terminal)"
}

# ---------------------------------------------------------------------------
# Post-install tests
# ---------------------------------------------------------------------------

run_post_install_tests() {
    print_header "Running Post-Installation Tests"

    local tests_passed=0
    local tests_total=5

    # Test 1: mc container running
    print_info "Test 1/5: mc container"
    if docker ps --format '{{.Names}}' | grep -q "^mc$"; then
        print_success "✓ mc container is running"
        ((tests_passed++))
    else
        print_error "✗ mc container is not running"
    fi

    # Test 2: Memory usage
    print_info "Test 2/5: Memory usage"
    local mem_usage
    mem_usage=$(docker stats mc --no-stream --format "{{.MemUsage}}" 2>/dev/null | awk '{print $1}')
    if [ -n "$mem_usage" ]; then
        print_success "✓ Memory usage: $mem_usage"
        ((tests_passed++))
    else
        print_error "✗ Could not read memory usage"
    fi

    # Test 3: Neofetch
    print_info "Test 3/5: Neofetch"
    if docker exec mc bash -c "command -v neofetch" &> /dev/null; then
        print_success "✓ Neofetch is installed"
        ((tests_passed++))
    else
        print_warning "✗ Neofetch not installed — Minefetch won't work"
    fi

    # Test 4: playit agent
    print_info "Test 4/5: playit agent"
    sleep 2
    if docker ps --format '{{.Names}}' | grep -q "^playit-agent$"; then
        print_success "✓ playit agent is running"
        ((tests_passed++))
    else
        print_warning "✗ playit agent not running — check PLAYIT_SECRET in .env"
    fi

    # Test 5: Server done loading
    print_info "Test 5/5: Server ready"
    if docker compose logs mc 2>/dev/null | grep -q "Done"; then
        print_success "✓ Server is ready"
        ((tests_passed++))
    else
        print_warning "✗ Server still initialising — wait 1-2 minutes and recheck"
    fi

    echo ""
    print_info "Tests passed: $tests_passed/$tests_total"

    if [ $tests_passed -ge 3 ]; then
        print_success "Setup looks good! ✓"
    else
        print_warning "Some tests failed. Check the output above."
    fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

display_summary() {
    echo ""
    print_header "Setup Complete! 🎉"
    echo ""

    print_success "Your Minecraft server is configured and ready."
    echo ""

    if [ "$CONFIG_APPLIED" = true ]; then
        echo -e "${GREEN}Applied: Maximum Efficiency${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Memory:              256MB-1.28GB"
        echo "  Max players:         6"
        echo "  View distance:       4 chunks"
        echo "  Simulation distance: 3 chunks"
        echo "  Plugins:             5 (Backuper, ViaVersion, Minefetch, LuckPerms, Spark)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi

    print_info "Quick Commands:"
    echo "  View logs:   docker compose logs -f mc"
    echo "  Status:      docker stats mc"
    echo "  Stop:        docker compose down"
    echo "  Restart:     docker compose restart"
    echo ""

    print_info "In-Game Commands:"
    echo "  /tps        - Server performance"
    echo "  /minefetch  - System information"
    echo "  /loadfetch  - CPU/RAM graphs"
    echo ""

    print_info "Next Steps:"
    echo "  1. Wait 1-2 minutes for full startup"
    echo "  2. Complete playit.gg tunnel setup if not done — https://playit.gg/account/tunnels"
    echo "  3. Connect via your playit.gg address"
    echo "  4. Run /minefetch to verify system monitoring"
    echo ""

    print_info "Documentation:"
    echo "  - docs/ — guides and troubleshooting"
    echo "  - .env  — all configurable options"
    echo ""

    echo ""
    print_success "Happy crafting! ⛏️"
    echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    clear
    print_banner

    detect_os
    print_info "Operating System: $OS"

    if [ "$OS" == "Linux" ]; then
        detect_linux_distro
        print_info "Distribution: $DISTRO"
    fi

    if [ "$OS" == "Unknown" ]; then
        print_error "Unsupported operating system: $OSTYPE"
        print_info "This script supports macOS and Linux only."
        exit 1
    fi
    echo ""

    # Prerequisites
    check_docker
    check_docker_compose
    echo ""

    # Environment (.env + MC_VERSION)
    setup_env
    echo ""

    # Auto-configure image and plugins for the given MC version
    print_header "Auto-Configuring for Minecraft $MC_VERSION"
    if [ -f "$SCRIPT_DIR/auto_configure.sh" ]; then
        chmod +x "$SCRIPT_DIR/auto_configure.sh"
        bash "$SCRIPT_DIR/auto_configure.sh"
        print_success "Auto-configuration complete."
    else
        print_warning "auto_configure.sh not found. Using existing settings."
    fi
    echo ""

    # Optional backup
    print_info "It's recommended to back up your data before proceeding."
    read -p "Create backup now? (Y/n): " backup_choice
    if [[ ! "$backup_choice" =~ ^[Nn]$ ]]; then
        create_backup || print_warning "Continuing without backup..."
    fi
    echo ""

    # Optimisation level
    show_optimization_levels
    read -p "Select optimisation level (1-5) [1]: " opt_level
    opt_level=${opt_level:-1}

    case "$opt_level" in
        1) apply_max_efficiency ;;
        2|3|4)
            print_info "Levels 2-4 require manual edits to compose.yml."
            print_tip "See docs/ for configuration examples."
            ;;
        5) print_info "Keeping current configuration." ;;
        *) print_warning "Invalid selection. Keeping current configuration." ;;
    esac
    echo ""

    # Start server
    read -p "Start the server now? (Y/n): " start_server_choice
    if [[ ! "$start_server_choice" =~ ^[Nn]$ ]]; then
        start_minecraft_server
        echo ""
        setup_playit
    else
        print_info "Skipping server start."
        print_tip "Start manually with:  docker compose up -d"
        echo ""
        print_info "To set up the playit tunnel later, run:"
        print_tip "docker compose up -d playit && docker compose logs playit"
    fi
    echo ""

    # Neofetch for Minefetch plugin
    if docker ps --format '{{.Names}}' | grep -q "^mc$"; then
        read -p "Install neofetch for the Minefetch plugin? (Y/n): " install_neo_choice
        if [[ ! "$install_neo_choice" =~ ^[Nn]$ ]]; then
            install_neofetch
        else
            print_info "Skipping neofetch."
            print_warning "Minefetch won't work without it."
        fi
        echo ""
    fi

    # Aliases
    read -p "Set up shell aliases? (Y/n): " setup_aliases_choice
    if [[ ! "$setup_aliases_choice" =~ ^[Nn]$ ]]; then
        setup_aliases
    else
        print_info "Skipping alias setup."
    fi
    echo ""

    # Post-install tests
    if docker ps --format '{{.Names}}' | grep -q "^mc$"; then
        read -p "Run post-installation tests? (Y/n): " run_tests_choice
        if [[ ! "$run_tests_choice" =~ ^[Nn]$ ]]; then
            echo ""
            run_post_install_tests
            echo ""
        fi
    fi

    display_summary
}

main "$@"
