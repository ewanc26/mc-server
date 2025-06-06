#!/bin/bash

SERVER_DIR="/Volumes/Storage/server"  # Adjust this path
INHIBIT_PID_FILE="/tmp/mc_inhibit.pid"
XSET_PID_FILE="/tmp/mc_xset.pid"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

mc_start() {
    echo -e "${GREEN}Starting Minecraft server...${NC}"
    cd "$SERVER_DIR" && docker compose up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Server started successfully. Preventing system sleep...${NC}"
        
        # Method 1: Use systemd-inhibit to prevent sleep/suspend
        if command -v systemd-inhibit >/dev/null 2>&1; then
            systemd-inhibit --what=sleep:idle --who="Minecraft Server" --why="Server is running" sleep infinity &
            echo $! > "$INHIBIT_PID_FILE"
            echo -e "${GREEN}Systemd sleep inhibitor enabled (PID: $!)${NC}"
        fi
        
        # Method 2: Disable screen blanking and DPMS (if running X11)
        if [ -n "$DISPLAY" ] && command -v xset >/dev/null 2>&1; then
            (
                while true; do
                    xset s off          # Disable screen saver
                    xset -dpms          # Disable DPMS (monitor power management)
                    xset s noblank      # Don't blank the screen
                    sleep 300           # Refresh every 5 minutes
                done
            ) &
            echo $! > "$XSET_PID_FILE"
            echo -e "${GREEN}X11 screen saver disabled (PID: $!)${NC}"
        fi
        
        echo -e "${YELLOW}System sleep prevention is now active${NC}"
    else
        echo -e "${RED}Failed to start server${NC}"
        return 1
    fi
}

mc_stop() {
    echo -e "${YELLOW}Stopping Minecraft server...${NC}"
    cd "$SERVER_DIR" && docker compose down
    
    # Stop systemd inhibitor
    if [ -f "$INHIBIT_PID_FILE" ]; then
        INHIBIT_PID=$(cat "$INHIBIT_PID_FILE")
        echo -e "${YELLOW}Stopping systemd sleep inhibitor (PID: $INHIBIT_PID)...${NC}"
        kill "$INHIBIT_PID" 2>/dev/null
        rm "$INHIBIT_PID_FILE"
    fi
    
    # Stop xset loop and restore settings
    if [ -f "$XSET_PID_FILE" ]; then
        XSET_PID=$(cat "$XSET_PID_FILE")
        echo -e "${YELLOW}Stopping X11 screen saver override (PID: $XSET_PID)...${NC}"
        kill "$XSET_PID" 2>/dev/null
        rm "$XSET_PID_FILE"
        
        # Restore default screen saver settings
        if [ -n "$DISPLAY" ] && command -v xset >/dev/null 2>&1; then
            xset s on           # Enable screen saver
            xset +dpms          # Enable DPMS
            xset s blank        # Allow screen blanking
            echo -e "${GREEN}X11 screen saver settings restored${NC}"
        fi
    fi
    
    echo -e "${GREEN}System sleep prevention disabled${NC}"
}

mc_status() {
    echo -e "${YELLOW}=== Server Status ===${NC}"
    cd "$SERVER_DIR" && docker compose ps
    
    echo -e "\n${YELLOW}=== Sleep Prevention Status ===${NC}"
    
    # Check systemd inhibitor
    if [ -f "$INHIBIT_PID_FILE" ]; then
        INHIBIT_PID=$(cat "$INHIBIT_PID_FILE")
        if ps -p "$INHIBIT_PID" > /dev/null 2>&1; then
            echo -e "${GREEN}Systemd sleep inhibitor is ACTIVE (PID: $INHIBIT_PID)${NC}"
        else
            echo -e "${RED}Systemd inhibitor PID file exists but process is dead${NC}"
            rm "$INHIBIT_PID_FILE"
        fi
    else
        echo -e "${RED}Systemd sleep inhibitor is INACTIVE${NC}"
    fi
    
    # Check xset loop
    if [ -f "$XSET_PID_FILE" ]; then
        XSET_PID=$(cat "$XSET_PID_FILE")
        if ps -p "$XSET_PID" > /dev/null 2>&1; then
            echo -e "${GREEN}X11 screen saver override is ACTIVE (PID: $XSET_PID)${NC}"
        else
            echo -e "${RED}X11 override PID file exists but process is dead${NC}"
            rm "$XSET_PID_FILE"
        fi
    else
        echo -e "${RED}X11 screen saver override is INACTIVE${NC}"
    fi
    
    # Show current inhibitors
    if command -v systemd-inhibit >/dev/null 2>&1; then
        echo -e "\n${YELLOW}=== Current System Inhibitors ===${NC}"
        systemd-inhibit --list 2>/dev/null || echo "No active inhibitors or unable to list"
    fi
}

mc_cleanup() {
    echo -e "${YELLOW}Cleaning up any orphaned processes...${NC}"
    
    # Clean up systemd inhibitors
    if [ -f "$INHIBIT_PID_FILE" ]; then
        INHIBIT_PID=$(cat "$INHIBIT_PID_FILE")
        kill "$INHIBIT_PID" 2>/dev/null
        rm "$INHIBIT_PID_FILE"
    fi
    
    # Clean up xset processes
    if [ -f "$XSET_PID_FILE" ]; then
        XSET_PID=$(cat "$XSET_PID_FILE")
        kill "$XSET_PID" 2>/dev/null
        rm "$XSET_PID_FILE"
        
        # Restore screen saver
        if [ -n "$DISPLAY" ] && command -v xset >/dev/null 2>&1; then
            xset s on
            xset +dpms
            xset s blank
        fi
    fi
    
    echo -e "${GREEN}Cleanup complete${NC}"
}

# Check if server directory exists
if [ ! -d "$SERVER_DIR" ]; then
    echo -e "${RED}Error: Server directory '$SERVER_DIR' does not exist!${NC}"
    echo -e "${YELLOW}Please update the SERVER_DIR variable in this script.${NC}"
    exit 1
fi

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
    cleanup)
        mc_cleanup
        ;;
    *)
        echo "Usage: $0 {start|stop|status|cleanup}"
        echo "  start   - Start server and prevent system sleep"
        echo "  stop    - Stop server and restore sleep settings"
        echo "  status  - Show server and sleep prevention status"
        echo "  cleanup - Clean up any orphaned sleep prevention processes"
        echo ""
        echo "Current server directory: $SERVER_DIR"
        ;;
esac