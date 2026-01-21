#!/bin/bash

# Hardware Detection and Dynamic Configuration Script
# Automatically optimizes Minecraft server settings based on available hardware

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Get total system RAM in MB
get_total_ram() {
    local os=$(detect_os)
    
    if [ "$os" == "macos" ]; then
        # macOS - use sysctl
        local ram_bytes=$(sysctl -n hw.memsize)
        echo $((ram_bytes / 1024 / 1024))
    elif [ "$os" == "linux" ]; then
        # Linux - use /proc/meminfo
        local ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        echo $((ram_kb / 1024))
    else
        echo "0"
    fi
}

# Get total CPU cores
get_cpu_cores() {
    local os=$(detect_os)
    
    if [ "$os" == "macos" ]; then
        sysctl -n hw.ncpu
    elif [ "$os" == "linux" ]; then
        nproc
    else
        echo "1"
    fi
}

# Calculate optimal Minecraft memory allocation
calculate_memory_allocation() {
    local total_ram=$1
    local allocation_percent=${2:-50}  # Default 50% of system RAM
    
    # Calculate base allocation
    local max_memory=$((total_ram * allocation_percent / 100))
    
    # Apply limits based on total RAM tiers
    if [ $total_ram -lt 2048 ]; then
        # < 2GB total RAM - Very conservative
        max_memory=$((total_ram * 40 / 100))
        [ $max_memory -lt 512 ] && max_memory=512
        [ $max_memory -gt 896 ] && max_memory=896
    elif [ $total_ram -lt 4096 ]; then
        # 2-4GB total RAM - Conservative
        max_memory=$((total_ram * 45 / 100))
        [ $max_memory -lt 896 ] && max_memory=896
        [ $max_memory -gt 1536 ] && max_memory=1536
    elif [ $total_ram -lt 8192 ]; then
        # 4-8GB total RAM - Balanced
        max_memory=$((total_ram * 50 / 100))
        [ $max_memory -lt 1536 ] && max_memory=1536
        [ $max_memory -gt 3072 ] && max_memory=3072
    elif [ $total_ram -lt 16384 ]; then
        # 8-16GB total RAM - Generous
        max_memory=$((total_ram * 50 / 100))
        [ $max_memory -lt 3072 ] && max_memory=3072
        [ $max_memory -gt 6144 ] && max_memory=6144
    else
        # 16GB+ total RAM - Very generous
        max_memory=$((total_ram * 40 / 100))
        [ $max_memory -lt 4096 ] && max_memory=4096
        [ $max_memory -gt 8192 ] && max_memory=8192
    fi
    
    echo $max_memory
}

# Calculate initial memory (typically 15-25% of max)
calculate_init_memory() {
    local max_memory=$1
    local init_memory=$((max_memory * 20 / 100))
    
    # Apply minimum and maximum limits
    [ $init_memory -lt 256 ] && init_memory=256
    [ $init_memory -gt 2048 ] && init_memory=2048
    
    echo $init_memory
}

# Calculate container memory limit (max + 25% overhead)
calculate_container_limit() {
    local max_memory=$1
    local container_limit=$((max_memory * 125 / 100))
    
    echo $container_limit
}

# Calculate optimal CPU allocation
calculate_cpu_allocation() {
    local total_cores=$1
    
    local cpu_limit=$total_cores
    local cpu_reserve=1
    
    # Adjust based on core count
    if [ $total_cores -le 2 ]; then
        cpu_limit=2
        cpu_reserve=1
    elif [ $total_cores -le 4 ]; then
        cpu_limit=$total_cores
        cpu_reserve=1
    elif [ $total_cores -le 8 ]; then
        cpu_limit=$((total_cores * 75 / 100))
        [ $cpu_limit -lt 4 ] && cpu_limit=4
        cpu_reserve=2
    else
        cpu_limit=$((total_cores * 60 / 100))
        [ $cpu_limit -lt 6 ] && cpu_limit=6
        cpu_reserve=2
    fi
    
    echo "$cpu_reserve $cpu_limit"
}

# Calculate optimal player count based on RAM
calculate_max_players() {
    local max_memory=$1
    
    if [ $max_memory -lt 1024 ]; then
        echo "4"
    elif [ $max_memory -lt 1536 ]; then
        echo "6"
    elif [ $max_memory -lt 2048 ]; then
        echo "8"
    elif [ $max_memory -lt 3072 ]; then
        echo "10"
    elif [ $max_memory -lt 4096 ]; then
        echo "12"
    else
        echo "16"
    fi
}

# Calculate view distance based on RAM
calculate_view_distance() {
    local max_memory=$1
    
    if [ $max_memory -lt 1024 ]; then
        echo "4"
    elif [ $max_memory -lt 1536 ]; then
        echo "5"
    elif [ $max_memory -lt 2048 ]; then
        echo "6"
    elif [ $max_memory -lt 3072 ]; then
        echo "7"
    else
        echo "8"
    fi
}

# Calculate simulation distance based on RAM
calculate_simulation_distance() {
    local max_memory=$1
    
    if [ $max_memory -lt 1024 ]; then
        echo "3"
    elif [ $max_memory -lt 2048 ]; then
        echo "4"
    elif [ $max_memory -lt 3072 ]; then
        echo "5"
    else
        echo "6"
    fi
}

# Determine optimization tier
determine_optimization_tier() {
    local total_ram=$1
    
    if [ $total_ram -lt 2048 ]; then
        echo "extreme"
    elif [ $total_ram -lt 4096 ]; then
        echo "maximum"
    elif [ $total_ram -lt 8192 ]; then
        echo "balanced"
    else
        echo "generous"
    fi
}

# Generate .env file with dynamic values
generate_env_file() {
    local output_file=$1
    
    print_info "Detecting hardware specifications..."
    
    # Get hardware info
    local total_ram=$(get_total_ram)
    local cpu_cores=$(get_cpu_cores)
    local os=$(detect_os)
    
    print_info "System RAM: ${total_ram}MB"
    print_info "CPU Cores: $cpu_cores"
    print_info "OS: $os"
    echo ""
    
    # Calculate optimal allocations
    local max_memory=$(calculate_memory_allocation $total_ram)
    local init_memory=$(calculate_init_memory $max_memory)
    local container_limit=$(calculate_container_limit $max_memory)
    local cpu_allocation=$(calculate_cpu_allocation $cpu_cores)
    local cpu_reserve=$(echo $cpu_allocation | awk '{print $1}')
    local cpu_limit=$(echo $cpu_allocation | awk '{print $2}')
    local max_players=$(calculate_max_players $max_memory)
    local view_distance=$(calculate_view_distance $max_memory)
    local simulation_distance=$(calculate_simulation_distance $max_memory)
    local optimization_tier=$(determine_optimization_tier $total_ram)
    
    print_info "Calculated Configuration:"
    echo "  Optimization Tier: $optimization_tier"
    echo "  Init Memory: ${init_memory}MB"
    echo "  Max Memory: ${max_memory}MB"
    echo "  Container Limit: ${container_limit}MB"
    echo "  CPU Reserve: ${cpu_reserve} cores"
    echo "  CPU Limit: ${cpu_limit} cores"
    echo "  Max Players: $max_players"
    echo "  View Distance: $view_distance chunks"
    echo "  Simulation Distance: $simulation_distance chunks"
    echo ""
    
    # Generate .env file
    cat > "$output_file" << EOF
# Auto-generated Minecraft Server Configuration
# Generated on: $(date)
# Based on detected hardware: ${total_ram}MB RAM, ${cpu_cores} CPU cores

# Hardware Detection
DETECTED_TOTAL_RAM=${total_ram}
DETECTED_CPU_CORES=${cpu_cores}
DETECTED_OS=${os}

# Memory Configuration
MC_INIT_MEMORY=${init_memory}M
MC_MAX_MEMORY=${max_memory}M
MC_CONTAINER_LIMIT=${container_limit}M

# CPU Configuration
MC_CPU_RESERVE=${cpu_reserve}.0
MC_CPU_LIMIT=${cpu_limit}.0

# Server Configuration
MC_MAX_PLAYERS=${max_players}
MC_VIEW_DISTANCE=${view_distance}
MC_SIMULATION_DISTANCE=${simulation_distance}

# Optimization Tier
MC_OPTIMIZATION_TIER=${optimization_tier}

# Entity Broadcast (based on tier)
EOF

    # Add tier-specific settings
    case "$optimization_tier" in
        extreme)
            cat >> "$output_file" << EOF
MC_ENTITY_BROADCAST=60
MC_NETWORK_COMPRESSION=64
MC_SPAWN_PROTECTION=2
MC_IDLE_TIMEOUT=3
MC_CHUNK_GC_PERIOD=300
EOF
            ;;
        maximum)
            cat >> "$output_file" << EOF
MC_ENTITY_BROADCAST=65
MC_NETWORK_COMPRESSION=128
MC_SPAWN_PROTECTION=4
MC_IDLE_TIMEOUT=5
MC_CHUNK_GC_PERIOD=400
EOF
            ;;
        balanced)
            cat >> "$output_file" << EOF
MC_ENTITY_BROADCAST=70
MC_NETWORK_COMPRESSION=256
MC_SPAWN_PROTECTION=8
MC_IDLE_TIMEOUT=8
MC_CHUNK_GC_PERIOD=600
EOF
            ;;
        generous)
            cat >> "$output_file" << EOF
MC_ENTITY_BROADCAST=75
MC_NETWORK_COMPRESSION=512
MC_SPAWN_PROTECTION=16
MC_IDLE_TIMEOUT=10
MC_CHUNK_GC_PERIOD=1200
EOF
            ;;
    esac
    
    print_success ".env file generated: $output_file"
    
    # Display recommendations
    echo ""
    print_info "Recommendations:"
    
    if [ $total_ram -lt 2048 ]; then
        print_warning "Limited RAM detected (<2GB)"
        echo "  - Consider running on a system with more RAM"
        echo "  - Expect 2-4 players maximum"
        echo "  - Monitor memory usage closely"
    elif [ $total_ram -lt 4096 ]; then
        print_info "Moderate RAM detected (2-4GB)"
        echo "  - Good for small servers (4-6 players)"
        echo "  - Should run smoothly with current settings"
    elif [ $total_ram -lt 8192 ]; then
        print_success "Good RAM detected (4-8GB)"
        echo "  - Great for medium servers (8-12 players)"
        echo "  - Plenty of headroom for plugins"
    else
        print_success "Excellent RAM detected (8GB+)"
        echo "  - Perfect for larger servers (12-20 players)"
        echo "  - Can handle many plugins and mods"
    fi
    
    echo ""
    
    return 0
}

# Main execution
main() {
    echo "========================================"
    echo "  Dynamic Hardware Configuration Tool"
    echo "========================================"
    echo ""
    
    # Check for output file argument
    local output_file="${1:-.env}"
    
    # Get absolute path
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local server_dir="$(dirname "$script_dir")"
    local env_path="$server_dir/$output_file"
    
    print_info "Generating configuration for: $env_path"
    echo ""
    
    # Generate .env file
    generate_env_file "$env_path"
    
    echo ""
    print_success "Configuration complete!"
    print_info "Apply these settings by restarting your server:"
    echo "  docker-compose down"
    echo "  docker-compose up -d"
    echo ""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
