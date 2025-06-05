# Ewan's Minecraft Server

This repository contains the necessary files to set up and run Ewan's Minecraft Server using Docker Compose. The server is configured with PaperMC, several Spigot resources, and a RealIP plugin. It also includes a companion script to set up dynamic DNS using DuckDNS. This setup is primarily intended for personal use or small groups of friends.

## Table of Contents

* [Ewan's Minecraft Server](#ewans-minecraft-server)
  * [Table of Contents](#table-of-contents)
  * [License](#license)
  * [Features](#features)
  * [System Requirements](#system-requirements)
    * [General](#general)
    * [Ubuntu Server 22.04.5 LTS](#ubuntu-server-22045-lts)
    * [macOS 15.5](#macos-155)
  * [Getting Started](#getting-started)
    * [Prerequisites](#prerequisites)
    * [Setup](#setup)
      * [Clone the Repository](#clone-the-repository)
      * [Configure `compose.yml`](#configure-composeyml)
      * [Initial Server Startup (EULA Acceptance)](#initial-server-startup-eula-acceptance)
  * [DuckDNS Setup (Optional)](#duckdns-setup-optional)
    * [What is DuckDNS?](#what-is-duckdns)
    * [Prerequisites for DuckDNS Script](#prerequisites-for-duckdns-script)
    * [Running the DuckDNS Setup Script](#running-the-duckdns-setup-script)
    * [macOS Specific Notes for DuckDNS](#macos-specific-notes-for-duckdns)
  * [Usage](#usage)
    * [Starting the Server](#starting-the-server)
    * [Stopping the Server](#stopping-the-server)
    * [Accessing the Console](#accessing-the-console)
    * [Player Whitelisting/Ops](#player-whitelistingops)
  * [Maintenance](#maintenance)
    * [Updating the Server Version](#updating-the-server-version)
    * [Plugin Management](#plugin-management)
    * [Backups](#backups)
  * [Troubleshooting](#troubleshooting)
  * [Contributing](#contributing)
  * [Contact](#contact)

## License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**. See the `LICENSE` file for more details.

## Features

* **Personal Use Optimised:** This setup is primarily configured for personal use or small groups of friends, balancing performance and ease of management for private gameplay.
* **PaperMC Server:** Optimised for performance and stability.
* **Dockerised:** Easy setup and consistent environment across different systems.
* **Automatic Plugin Management:** Includes pre-configured plugins (TCPShield RealIP, and others via Spigot Resources).
* **Configurable:** Easily modify server settings via `compose.yml`.
* **Persistent Data:** Server worlds and configurations are stored persistently in the `./data` directory.
* **Dynamic DNS Integration (DuckDNS):** Companion script for automatic IP address updates, allowing players to connect via a consistent domain name.

## System Requirements

### General

* **Docker Engine:** Version 20.10 or higher.
* **Docker Compose V2:** Included with Docker Desktop and recommended for all installations.
* **Minimum 4GB RAM:** Dedicated to the Minecraft server (configured in `compose.yml`). More is recommended for larger player counts or complex worlds.
* **Sufficient Disk Space:** For world data and backups.

### Ubuntu Server 22.04.5 LTS

Ensure your Ubuntu server is up-to-date.

```bash
sudo apt update
sudo apt upgrade -y
````

**Install Docker Engine and Docker Compose V2:**

It is highly recommended to install Docker Engine and Docker Compose V2 using the official Docker repository, which ensures you get the latest versions.

Follow the official Docker documentation for installing Docker Engine and Docker Compose on Ubuntu:

  * [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
  * [Install Docker Compose on Ubuntu](https://docs.docker.com/compose/install/) (Docker Compose V2 is typically installed as a plugin for Docker Engine).

Alternatively, if you prefer using `apt` (though this might provide slightly older versions, still likely V2):

```bash
# Install Docker Engine
sudo apt install docker.io -y
sudo systemctl enable --now docker

# Add your user to the docker group to run docker commands without sudo
sudo usermod -aG docker "$USER"
newgrp docker # Apply group changes immediately
```

For Docker Compose V2 (as a plugin for Docker Engine):

```bash
sudo apt install docker-compose-plugin -y
```

Verify installation:

```bash
docker --version
docker compose version # Note the space: this is the Docker Compose V2 command
```

### macOS 15.5

**Install Docker Desktop for Mac:**

Download and install Docker Desktop for Mac from the official Docker website:

  * [Download Docker Desktop](https://docs.docker.com/desktop/install/mac-install/)

Docker Desktop includes Docker Engine and **Docker Compose V2** natively. After installation, ensure Docker Desktop is running.

Verify installation in your terminal:

```bash
docker --version
docker compose version # Note the space: this is the Docker Compose V2 command
```

## Getting Started

### Prerequisites

Before proceeding, ensure you have:

  * Satisfied the [System Requirements](https://www.google.com/search?q=%23system-requirements) for your operating system.
  * An active internet connection to download Docker images and plugins.

### Setup

#### Clone the Repository

First, clone this repository to your local machine:

```bash
git clone [https://github.com/ewanc26/mc-server.git](https://github.com/ewanc26/mc-server.git)
cd mc-server
```

#### Configure `compose.yml`

The `compose.yml` file is pre-configured based on your setupmc.com generation. You may want to review and modify it to suit your needs.

Key variables to consider:

  * `VERSION`: Minecraft server version (e.g., `1.21.1`).
  * `MEMORY`: RAM allocated to the server (e.g., `4096M`).
  * `MAX_PLAYERS`: Maximum number of players.
  * `MOTD`: Message of the Day.
  * `OPS`: List of player usernames to grant operator (OP) status.
  * `SPIGET_RESOURCES`: List of Spigot resource IDs to download.
  * `PLUGINS`: Direct URLs to `.jar` plugins.
  * `BUG_REPORT_LINK`: Link for bug reports.
  * `TZ`: Time zone (e.g., `Europe/London`).

**Example `compose.yml` snippet:**

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
      SPIGET_RESOURCES: |-\
        1997
        125742
        94532
        82861
        19254
        27448
      PLUGINS: |-
        [https://github.com/TCPShield/RealIP/releases/download/2.8.1/TCPShield-2.8.1.jar](https://github.com/TCPShield/RealIP/releases/download/2.8.1/TCPShield-2.8.1.jar)
      BUG_REPORT_LINK: "[https://github.com/ewanc26/mc-server/issues](https://github.com/ewanc26/mc-server/issues)"
    volumes:
      - "./data:/data"
```

The server data (world, configurations, logs) will be stored in the `./data` directory relative to where your `compose.yml` file is located.

#### Initial Server Startup (EULA Acceptance)

The `EULA: "TRUE"` environment variable in `compose.yml` automatically accepts the Minecraft EULA. If this were set to `FALSE` or omitted, the server would not start until you manually set `eula=true` in `data/eula.txt`. Since it's set to `TRUE`, you can proceed directly to starting the server.

## DuckDNS Setup (Optional)

This section details how to set up dynamic DNS for your Minecraft server using DuckDNS and the provided `setup_duckdns.sh` script. This is highly recommended if your server does not have a static public IP address, as it allows players to always connect using a consistent domain name (e.g., `yourserver.duckdns.org`).

### What is DuckDNS?

DuckDNS is a free dynamic DNS service that points a subdomain under `duckdns.org` to your current public IP address. The provided script automates the process of updating your DuckDNS record hourly.

### Prerequisites for DuckDNS Script

Before running the `setup_duckdns.sh` script, ensure you have:

  * **A DuckDNS account and domain:** Register at [duckdns.org](https://www.duckdns.org/).
  * **Your DuckDNS domain(s) and token:** You will need these during script execution.
  * `curl` installed (for IP detection and DuckDNS API calls).
  * `cron` installed (for scheduling hourly updates).

**Installation of `curl` and `cron`:**

  * **Ubuntu Server 22.04.5:**
    ```bash
    sudo apt update && sudo apt install curl cron -y
    ```
  * **macOS 15.5:** `curl` is typically pre-installed. `cron` is also available, though `launchd` is a more macOS-native scheduling tool (see notes below). If `curl` is missing, you can install it via Homebrew:
    ```bash
    /bin/bash -c "$(curl -fsSL [https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh))"
    brew install curl
    ```

### Running the DuckDNS Setup Script

1.  Navigate to the root directory of your cloned repository (where `setup_duckdns.sh` is located).
    ```bash
    cd mc-server
    ```
2.  Make the script executable:
    ```bash
    chmod +x setup_duckdns.sh
    ```
3.  Run the script. **Important:** Do NOT run this script as root (`sudo`). It will prompt for `sudo` credentials if needed for `cron` setup.
    ```bash
    ./setup_duckdns.sh
    ```
4.  Follow the on-screen prompts to enter your DuckDNS domain, token, and preferred IP detection method.
5.  The script will test the update and then set up an hourly cron job to keep your DuckDNS record updated.

### macOS Specific Notes for DuckDNS

While the `setup_duckdns.sh` script uses `cron`, macOS has some specifics:

  * **Full Disk Access:** Cron jobs might require "Full Disk Access" permission for your Terminal application (or iTerm, etc.). If you encounter permission issues, go to `System Settings > Privacy & Security > Full Disk Access` and add your terminal application.
  * **`launchd`:** For better macOS integration and more reliable scheduling, you might consider converting the cron job to a `launchd` plist. The `setup_duckdns.sh` script does not automate this, but it's a common practice on macOS.

## Usage

#### Starting the Server

Navigate to the directory containing `compose.yml` and run:

```bash
docker compose up -d
```

  * `up`: Creates and starts the Docker containers.
  * `-d`: Runs the containers in detached mode (in the background).

The server will download the necessary Minecraft server JAR and plugins on the first run. This may take some time depending on your internet connection.

You can monitor the server startup process by viewing logs:

```bash
docker compose logs -f mc
```

Press `Ctrl+C` to exit log viewing.

#### Stopping the Server

To stop the server cleanly:

```bash
docker compose down
```

This command stops the containers and removes them, but preserves the `./data` volume.

#### Accessing the Console

To attach to the Minecraft server console and run commands (e.g., `op <playername>`, `save-all`):

```bash
docker compose exec mc rcon-cli
```

To exit the RCON console, type `exit` and press Enter.

#### Player Whitelisting/Ops

Players listed under the `OPS` environment variable in `compose.yml` will automatically be granted operator status on server startup. You can also manually `op` players via the console:

```bash
docker compose exec mc rcon-cli op <player_username>
```

For whitelisting, you might need to manage `whitelist.json` within the `./data` directory or use `whitelist add <player_username>` via the RCON console if whitelisting is enabled.

### Maintenance

#### Updating the Server Version

To update the Minecraft server to a newer version:

1.  Stop the server:
    ```bash
    docker compose down
    ```
2.  Edit `compose.yml` and change the `VERSION` environment variable to your desired Minecraft version (e.g., `1.21.2`).
3.  Start the server:
    ```bash
    docker compose up -d
    ```
    The `itzg/minecraft-server` image will detect the version change and download the new server JAR.

#### Plugin Management

  * **Adding/Removing Spigot Resources:** Edit the `SPIGET_RESOURCES` list in `compose.yml`. Each ID should be on a new line.
  * **Adding/Removing Direct Plugins:** Edit the `PLUGINS` list in `compose.yml`. Each URL should be on a new line.
  * **Manual Plugin Management:** You can also place `.jar` files directly into the `./data/plugins` directory. Remember to restart the server (`docker compose restart mc`) after making manual changes.

#### Backups

The server data is stored in the `./data` directory. Regularly back up this directory to prevent data loss. A dedicated backup script (`backup_minecraft.sh`) is provided for this purpose.

**Using the Backup Script:**

1.  Ensure the server is stopped before running the backup script to prevent data corruption.
    ```bash
    docker compose down
    ```
2.  Make the backup script executable (if you haven't already):
    ```bash
    chmod +x backup_minecraft.sh
    ```
3.  Run the backup script from the root directory of your cloned repository:
    ```bash
    ./backup_minecraft.sh
    ```
    This will create a gzipped tar archive of your `./data` directory in the `backups/` subdirectory (relative to your script's location), with a timestamp in the filename.
4.  Once the backup is complete, you can restart your server:
    ```bash
    docker compose up -d
    ```

### Troubleshooting

  * **Server not starting:**
      * Check `docker compose logs mc` for error messages.
      * Ensure Docker is running and you have sufficient memory.
      * Verify `EULA: "TRUE"` in `compose.yml`.
  * **Cannot connect to server:**
      * Ensure port `25565` is open on your firewall (Ubuntu Server).
      * Verify the server is running (`docker compose ps`).
      * Check your client's Minecraft version matches the server's.
      * If using DuckDNS, ensure the `setup_duckdns.sh` script is running and your IP is correctly updated on duckdns.org.
  * **Plugins not loading:**
      * Check server logs for plugin-related errors.
      * Ensure plugins are compatible with your Minecraft server version.
      * Verify correct Spigot IDs or direct URLs in `compose.yml`.

If you encounter persistent issues, please report them at the [Bug Report Link](https://github.com/ewanc26/mc-server/issues) specified in the `compose.yml`.

## Contributing

Feel free to fork this repository, make improvements, and submit pull requests.

## Contact

For any questions or issues, please refer to the [Bug Report Link](https://github.com/ewanc26/mc-server/issues) provided in the `compose.yml`.
