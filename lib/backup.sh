#!/bin/bash
# Backup utilities for Minecraft server.
# Requires: shared.sh

create_backup() {
    local data_dir="${MC_DATA_DIR:-/Volumes/Storage/Server/MC/data}"
    local compose_file="${COMPOSE_FILE:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")/compose.yml}"
    local backup_dir="${BACKUP_DIR:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")/data_backups}"

    print_header "Creating Backup"

    if [ ! -d "$data_dir" ]; then
        print_warning "No data directory found at $data_dir. Skipping backup."
        return 0
    fi

    mkdir -p "$backup_dir"

    local backup_name="data_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$backup_dir/$backup_name"

    print_info "Creating backup: $backup_name"
    print_info "This may take a few minutes..."

    if cp -r "$data_dir" "$backup_path"; then
        print_success "Backup created at: $backup_path"
        if [ -f "$compose_file" ]; then
            cp "$compose_file" "$backup_path/compose.yml.backup"
            print_success "compose.yml backed up as well."
        fi
        return 0
    else
        print_error "Failed to create backup."
        return 1
    fi
}
