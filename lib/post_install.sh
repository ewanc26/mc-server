#!/bin/bash
# Post-installation tests for Minecraft server.
# Requires: shared.sh

run_post_install_tests() {
    local compose_file="${COMPOSE_FILE:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")/compose.yml}"

    print_header "Running Post-Installation Tests"

    local tests_passed=0
    local tests_total=5

    # Test 1: mc container running
    print_info "Test 1/$tests_total: mc container"
    if docker ps --format '{{.Names}}' | grep -q "^mc$"; then
        print_success "✓ mc container is running"
        ((tests_passed++))
    else
        print_error "✗ mc container is not running"
    fi

    # Test 2: Memory usage
    print_info "Test 2/$tests_total: Memory usage"
    local mem_usage
    mem_usage=$(docker stats mc --no-stream --format "{{.MemUsage}}" 2>/dev/null | awk '{print $1}')
    if [ -n "$mem_usage" ]; then
        print_success "✓ Memory usage: $mem_usage"
        ((tests_passed++))
    else
        print_error "✗ Could not read memory usage"
    fi

    # Test 3: Sysinfo mount
    print_info "Test 3/$tests_total: Sysinfo mount"
    if docker exec mc bash -c "test -f /sysinfo/host.json" &> /dev/null; then
        print_success "✓ /sysinfo/host.json is mounted"
        ((tests_passed++))
    else
        print_warning "✗ /sysinfo/host.json not found — check MC_SYSINFO_DIR mount"
    fi

    # Test 4: playit agent
    print_info "Test 4/$tests_total: playit agent"
    sleep 2
    if docker ps --format '{{.Names}}' | grep -q "^playit-agent$"; then
        print_success "✓ playit agent is running"
        ((tests_passed++))
    else
        print_warning "✗ playit agent not running — check PLAYIT_SECRET in .env"
    fi

    # Test 5: Server done loading
    print_info "Test 5/$tests_total: Server ready"
    if docker compose -f "$compose_file" logs mc 2>/dev/null | grep -q "Done"; then
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
