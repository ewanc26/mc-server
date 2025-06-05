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
        1997
        125742
        94532
        82861
        19254
        27448
      PLUGINS: |-
        https://github.com/TCPShield/RealIP/releases/download/2.8.1/TCPShield-2.8.1.jar
      BUG_REPORT_LINK: "https://github.com/ewanc26/mc-server/issues"
    volumes:
      - "./data:/data"
```

#### Initial Server Startup

The environment variable `EULA: "TRUE"` automatically accepts Minecraft’s EULA, allowing the server to start without manual intervention.
