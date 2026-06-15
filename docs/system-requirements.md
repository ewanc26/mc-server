# System Requirements

## General

- **Docker Engine:** Version 20.10 or higher (Docker Compose V2 required).
- **RAM:** 512MB minimum available to Docker; 1-2GB recommended for comfortable headroom.
- **Disk space:** Sufficient for world data and backups at `/Volumes/Storage/Server/MC`.

## macOS

Install **OrbStack** (recommended) or **Docker Desktop**:

- [OrbStack](https://orbstack.dev) — lighter, faster, native on Apple Silicon
- [Docker Desktop](https://docs.docker.com/desktop/install/mac-install/)

Verify:

```bash
docker --version
docker compose version
```

## Linux (Ubuntu 22.04+)

Keep your system up to date:

```bash
sudo apt update && sudo apt upgrade -y
```

Install Docker Engine and Compose V2:

```bash
sudo apt install docker.io docker-compose-plugin -y
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
newgrp docker
```

Or follow the [official Docker docs](https://docs.docker.com/engine/install/ubuntu/).

Verify:

```bash
docker --version
docker compose version
```
