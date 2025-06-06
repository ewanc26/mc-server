# Ewan's Minecraft Server

This repository contains the necessary files to set up and run Ewan's Minecraft Server using Docker Compose. The server is configured with PaperMC, several Spigot resources, and a RealIP plugin. It also includes a companion script to set up dynamic DNS using DuckDNS.

This setup is primarily intended for personal use or small groups of friends.

## Table of Contents

* [License](./LICENSE)
* [Features](./docs/features.md)
* [System Requirements](./docs/system-requirements.md)
* [Getting Started](./docs/getting-started.md)
* [DuckDNS Setup (Optional)](./docs/duckdns.md)
* [Usage](./docs/usage.md)
* [Maintenance](./docs/maintenance.md)
* [Troubleshooting](./docs/troubleshooting.md)
* [Contributing](./docs/contributing.md)
* [Contact](./docs/contact.md)

## How to Use the Scripts

To get started with the server setup, run the master setup script:

```bash
./scripts/setup_master.sh
```

This script will guide you through the initial setup, including Docker checks, DuckDNS configuration (optional), and starting the Minecraft server.

### Managing the Minecraft Server

Once the server is set up, you can manage its status using the OS-specific scripts located in the `scripts/` directory:

**For macOS:**

```bash
./scripts/server_status_mac.sh start   # To start the server
./scripts/server_status_mac.sh stop    # To stop the server
./scripts/server_status_mac.sh status  # To check server status
```

**For Linux:**

```bash
./scripts/server_status_linux.sh start   # To start the server
./scripts/server_status_linux.sh stop    # To stop the server
./scripts/server_status_linux.sh status  # To check server status
./scripts/server_status_linux.sh cleanup # To clean up orphaned sleep prevention processes
```
