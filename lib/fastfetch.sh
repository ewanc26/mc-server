#!/bin/bash
# Fastfetch setup for Minefetch — installs fastfetch on the host and starts the
# sysinfo watcher so the /minefetch in-game command shows fresh host data.
# Requires: shared.sh

SYSINFO_WATCHER="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/scripts/sysinfo-watcher.sh"
SYSINFO_DIR="${MC_SYSINFO_DIR:-/Volumes/Storage/Server/MC/sysinfo}"

setup_fastfetch() {
    print_header "Setting up fastfetch + sysinfo watcher for Minefetch"

    detect_os

    if command -v fastfetch &> /dev/null; then
        local version
        version=$(fastfetch --version 2>&1 | head -1)
        print_success "fastfetch already installed: $version"
    else
        print_info "Installing fastfetch..."
        case "$OS" in
            macOS)
                if ! command -v brew &> /dev/null; then
                    print_error "Homebrew not found. Install it from https://brew.sh"
                    return 1
                fi
                brew install fastfetch
                ;;
            Linux)
                local distro
                distro=$(detect_linux_distro)
                case "$distro" in
                    ubuntu|debian)
                        sudo apt-get update -qq && sudo apt-get install -y fastfetch
                        ;;
                    fedora)
                        sudo dnf install -y fastfetch
                        ;;
                    *)
                        print_warning "Unknown distro. Install fastfetch manually."
                        return 1
                        ;;
                esac
                ;;
            *)
                print_error "Unsupported OS: $OS"
                return 1
                ;;
        esac
    fi

    mkdir -p "$SYSINFO_DIR"

    local watcher_pid
    watcher_pid=$(pgrep -f "sysinfo-watcher.sh" 2>/dev/null || true)
    if [ -n "$watcher_pid" ]; then
        print_success "Sysinfo watcher already running (PID $watcher_pid)"
    else
        print_info "Starting sysinfo watcher in background..."
        nohup bash "$SYSINFO_WATCHER" "$SYSINFO_DIR" > /tmp/sysinfo-watcher.log 2>&1 &
        local pid=$!
        disown "$pid"
        print_success "Sysinfo watcher started (PID $pid)"

        # Generate initial host.json
        fastfetch --format json > "$SYSINFO_DIR/host.json.tmp"
        mv "$SYSINFO_DIR/host.json.tmp" "$SYSINFO_DIR/host.json"
        print_success "Initial host.json written to $SYSINFO_DIR/host.json"
    fi

    echo ""
    print_success "Minefetch sysinfo setup complete!"
    echo "Players can use /minefetch in-game to see fresh host data."
    echo "The watcher polls every 500ms for .refresh triggers from the plugin."
}
