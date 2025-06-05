# Getting Started

## Prerequisites

* Ensure [System Requirements](system-requirements.md) are met.
* Active internet connection.

## Setup

### Clone the Repository

```bash
git clone https://github.com/ewanc26/mc-server.git
cd mc-server
```

#### Configure `compose.yml`

```yaml
services:
  mc:
    image: itzg/minecraft-server:latest
    ports:
      - "25565:25565"
    environment:
      EULA: "TRUE"
      TYPE: "PAPER"
      VERSION: "1.21.1"
      MEMORY: "4096M"
      MAX_PLAYERS: "10"
      MOTD: "Ewan's Minecraft Server"
      OPS: |-
        GreenZero26
      SPIGET_RESOURCES: |-
        1997 # ProtocolLib
      PLUGINS: |-
        https://github.com/TCPShield/RealIP/releases/download/2.8.1/TCPShield-2.8.1.jar
        https://cdn.modrinth.com/data/7cMAqMND/versions/EwMrWdPh/Backuper-3.4.1.jar
        https://hangarcdn.papermc.io/plugins/alex3025/Headstones/versions/1.0.0/PAPER/Headstones-1.0.0.jar
      BUG_REPORT_LINK: "https://github.com/ewanc26/mc-server/issues"
    volumes:
      - "./data/minecraft:/data"
```

#### Initial Server Startup

The environment variable `EULA: "TRUE"` automatically accepts Minecraft’s EULA, allowing the server to start without manual intervention.
