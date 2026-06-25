#!/bin/bash
# Neofetch installation for Minecraft server container.
# Requires: shared.sh

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
