#!/bin/bash

# Minecraft Server Backup Script
# This script creates a compressed backup of the Minecraft server data directory.

# --- Configuration ---
# Directory where the compose.yml and 'data' directory are located.
# This script assumes it's run from the root of the repository.
SERVER_ROOT_DIR="$(dirname "$(realpath "$0")")"

# The directory containing the Minecraft server world and configurations.
# This should match the volume mapping in your compose.yml (e.g., ./data).
DATA_DIR="$SERVER_ROOT_DIR/data"

# The directory where backups will be stored.
BACKUP_DIR="$SERVER_ROOT_DIR/backups"

# --- Functions ---

# Function to print colored messages
print_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# --- Main Script ---

print_info "Starting Minecraft server backup..."

# 1. Check if the data directory exists
if [ ! -d "$DATA_DIR" ]; then
    print_error "Error: Minecraft data directory not found at '$DATA_DIR'."
    print_error "Please ensure you run this script from the root of your Minecraft server repository."
    exit 1
fi

# 2. Ensure the backup directory exists
mkdir -p "$BACKUP_DIR" || { print_error "Error: Failed to create backup directory '$BACKUP_DIR'."; exit 1; }

# 3. Generate a timestamp for the backup filename
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_FILENAME="minecraft_server_backup_${TIMESTAMP}.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

# 4. Check if the Docker container is running and warn the user
# A clean backup should be performed when the server is stopped.
print_info "Checking if Minecraft server Docker container is running..."
if docker compose ps -q mc &>/dev/null; then
    print_warning "Warning: The Minecraft server Docker container ('mc') appears to be running."
    print_warning "It is highly recommended to stop the server before backing up to prevent data corruption."
    read -p "Do you want to proceed with the backup while the server might be running? (y/N): " -n 1 -r
    echo # New line after the prompt
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Backup aborted. Please stop the server using 'docker compose down' and try again."
        exit 0
    fi
fi

print_info "Creating backup of '$DATA_DIR' to '$BACKUP_PATH'..."

# 5. Create the gzipped tar archive
# Using `$(basename "$DATA_DIR")` ensures that the 'data' directory itself is included
# as the top-level directory inside the tar archive, rather than just its contents.
tar -czvf "$BACKUP_PATH" -C "$(dirname "$DATA_DIR")" "$(basename "$DATA_DIR")"

# 6. Check if the backup was successful
if [ $? -eq 0 ]; then
    print_success "Backup completed successfully!"
    print_info "Backup saved to: $BACKUP_PATH"
    print_info "To restore, stop the server, extract the backup to replace the 'data' directory, then restart the server."
else
    print_error "Error: Backup failed. Please check the console output for details."
    exit 1
fi

print_info "Backup script finished."

