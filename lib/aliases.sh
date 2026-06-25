#!/bin/bash
# Shell alias setup for Minecraft server commands.
# Requires: shared.sh

setup_aliases() {
    local script_dir="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)}"
    local compose_file="${COMPOSE_FILE:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")/compose.yml}"

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
        echo "alias mcserver='$script_dir/$alias_script'"
        echo "alias mclog='docker compose -f $compose_file logs -f mc'"
        echo "alias mcstats='docker stats mc'"
        echo "alias mcstart='docker compose -f $compose_file up -d'"
        echo "alias mcstop='docker compose -f $compose_file down'"
        echo "alias mcrestart='docker compose -f $compose_file restart'"
    } >> "$shell_profile"

    print_success "Aliases added to $shell_profile."
    print_info "Available aliases: mcserver, mclog, mcstats, mcstart, mcstop, mcrestart"
    print_tip "Run:  source $shell_profile  (or restart your terminal)"
}
