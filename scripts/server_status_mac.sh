#!/bin/bash

SERVER_DIR="$(dirname "$(dirname "$(realpath "$0")")")"

TEMP_DIR="$SERVER_DIR/temp"
if [ ! -d "$TEMP_DIR" ]; then
    mkdir -p "$TEMP_DIR"
fi

CAFFEINE_PID_FILE="$TEMP_DIR/.mc_caffeine.pid"

mc_start() {
    echo "Starting Minecraft server..."
    cd "$SERVER_DIR" && docker compose up -d
    
    if [ $? -eq 0 ]; then
        echo "Server started successfully. Enabling caffeine..."
        # Start caffeinate in background and save PID
        caffeinate -d &
        echo $! > "$CAFFEINE_PID_FILE"
        echo "Caffeine enabled (PID: $!)"
    else
        echo "Failed to start server"
        return 1
    fi
}

mc_stop() {
    echo "Stopping Minecraft server..."
    cd "$SERVER_DIR" && docker compose down
    
    # Stop caffeine if PID file exists
    if [ -f "$CAFFEINE_PID_FILE" ]; then
        CAFFEINE_PID=$(cat "$CAFFEINE_PID_FILE")
        echo "Stopping caffeine (PID: $CAFFEINE_PID)..."
        kill "$CAFFEINE_PID" 2>/dev/null
        rm "$CAFFEINE_PID_FILE"
        echo "Caffeine disabled"
    fi
}

mc_status() {
    echo "=== Server Status ==="
    cd "$SERVER_DIR" && docker compose ps
    
    echo -e "\n=== Caffeine Status ==="
    if [ -f "$CAFFEINE_PID_FILE" ]; then
        CAFFEINE_PID=$(cat "$CAFFEINE_PID_FILE")
        if ps -p "$CAFFEINE_PID" > /dev/null 2>&1; then
            echo "Caffeine is ACTIVE (PID: $CAFFEINE_PID)"
        else
            echo "Caffeine PID file exists but process is dead"
            rm "$CAFFEINE_PID_FILE"
        fi
    else
        echo "Caffeine is INACTIVE"
    fi
}

# Function to add to your shell profile
case "$1" in
    start)
        mc_start
        ;;
    stop)
        mc_stop
        ;;
    status)
        mc_status
        ;;
    restart)
        mc_stop
        mc_start
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        echo "  start  - Start server and enable caffeine"
        echo "  stop   - Stop server and disable caffeine"
        echo "  status - Show server and caffeine status"
        echo "  restart - Restart server and caffeine"
        ;;
esac