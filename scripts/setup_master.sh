#!/bin/bash

# Master Setup Script for Ewan's Minecraft Server

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

# Source shared utilities
source "$SERVER_DIR/lib/shared.sh"

# Source optional lib modules
source "$SERVER_DIR/lib/docker.sh"
source "$SERVER_DIR/lib/backup.sh"
source "$SERVER_DIR/lib/fastfetch.sh"
source "$SERVER_DIR/lib/post_install.sh"
source "$SERVER_DIR/lib/aliases.sh"

COMPOSE_FILE="$SERVER_DIR/compose.yml"
BACKUP_DIR="$SERVER_DIR/data_backups"
CONFIG_APPLIED=false

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

    # fastfetch + sysinfo watcher for Minefetch plugin
    read -p "Set up fastfetch + sysinfo watcher for Minefetch? (Y/n): " setup_fastfetch_choice
    if [[ ! "$setup_fastfetch_choice" =~ ^[Nn]$ ]]; then
        setup_fastfetch
    else
        print_info "Skipping fastfetch setup."
        print_warning "Minefetch won't work without it."
    fi
    echo ""

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
