#!/bin/bash
# Docker prerequisite checks for Minecraft server.
# Requires: shared.sh

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
