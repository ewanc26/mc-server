# System Requirements

## General

* **Docker Engine:** Version 20.10 or higher.
* **Docker Compose V2:** Included with Docker Desktop and recommended for all installations.
* **Minimum 4GB RAM:** Dedicated to the Minecraft server (configured in `compose.yml`). More is recommended for larger player counts or complex worlds.
* **Sufficient Disk Space:** For world data and backups.

## Ubuntu Server 22.04.5 LTS

Ensure your Ubuntu server is up-to-date:

```bash
sudo apt update
sudo apt upgrade -y
````

**Install Docker Engine and Docker Compose V2:**

Follow the official Docker documentation:

* [https://docs.docker.com/engine/install/ubuntu/](https://docs.docker.com/engine/install/ubuntu/)
* [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)

Or, using `apt`:

```bash
sudo apt install docker.io -y
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
newgrp docker
sudo apt install docker-compose-plugin -y
```

Verify installation:

```bash
docker --version
docker compose version
```

## macOS 15.5

**Install Docker Desktop for Mac:**

Download from:

* [https://docs.docker.com/desktop/install/mac-install/](https://docs.docker.com/desktop/install/mac-install/)

Verify installation:

```bash
docker --version
docker compose version
```
