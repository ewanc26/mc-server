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

### How to Use the Scripts

This project includes several utility scripts located in the `scripts/` directory. These scripts are designed to help you manage your Minecraft server.

1. **`setup_master.sh`**: This is the main setup script. Run it first to ensure all prerequisites are met and to configure your server. This script will also offer to set up a convenient alias for the server status script.

    ```bash
    ./scripts/setup_master.sh
    ```

2. **`server_status_mac.sh` / `server_status_linux.sh`**: These scripts are OS-specific and allow you to start, stop, and check the status of your Minecraft server. If you allowed `setup_master.sh` to create the alias, you can use `mcserver` followed by the command.

    * **Using the `mcserver` alias (recommended after running `setup_master.sh`):

        * **Start the server:**

            ```bash
            mcserver start
            ```

        * **Stop the server:**

            ```bash
            mcserver stop
            ```

        * **Check server status:**

            ```bash
            mcserver status
            ```

    * **Directly running the scripts (if alias is not set up or preferred):

        * **Start the server:**

            ```bash
            ./scripts/server_status_mac.sh start   # For macOS
            ./scripts/server_status_linux.sh start # For Linux
            ```

        * **Stop the server:**

            ```bash
            ./scripts/server_status_mac.sh stop    # For macOS
            ./scripts/server_status_linux.sh stop  # For Linux
            ```

        * **Check server status:**

            ```bash
             ./scripts/server_status_mac.sh status   # For macOS
             ./scripts/server_status_linux.sh status # For Linux
             ```
