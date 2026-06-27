# Ewan's Minecraft Server

A Dockerised PaperMC server configured for small groups, with tunnelled public access via [playit.gg](https://playit.gg) — no port forwarding required.

## Table of Contents

* [License](./LICENSE)
* [Features](./docs/features.md)
* [System Requirements](./docs/system-requirements.md)
* [Getting Started](#getting-started)
* [playit.gg Tunnel Setup](./docs/duckdns.md)
* [Usage](./docs/usage.md)
* [Maintenance](./docs/maintenance.md)
* [Troubleshooting](./docs/troubleshooting.md)
* [Contributing](./docs/contributing.md)
* [Contact](./docs/contact.md)
* [Rules](./docs/rules.md)

## Getting Started

### Prerequisites

* Docker Desktop (or OrbStack on macOS)
* A [playit.gg](https://playit.gg) account

### 1. Clone the repository

```bash
git clone https://github.com/ewanc26/mc-server.git
cd mc-server
```

### 2. Configure the environment

```bash
cp .env.example .env
```

Open `.env` and set at minimum:

* `MC_VERSION` — Minecraft version to run (e.g. `1.21.1`)
* `PLAYIT_SECRET` — leave blank for now; see step 4

Then run the auto-configuration script to select the correct Java image and JVM flags (plugins are managed separately, via `MC_MODRINTH_PROJECTS` / `MC_SPIGET_RESOURCES` in `.env`):

```bash
MC_VERSION=1.21.1 ./scripts/auto_configure.sh
```

### 3. Start the server

```bash
docker compose up -d
```

### 4. Claim the playit.gg tunnel

On first run without a `PLAYIT_SECRET`, the playit agent prints a claim URL:

```bash
docker compose logs playit
```

Open the URL, sign into playit.gg, and add a **Minecraft** tunnel pointed at `mc:25565`. Copy the secret key from the dashboard into `.env`:

```
PLAYIT_SECRET=your_secret_here
```

Then apply it (a plain `restart` won't pick up the new secret — the container needs recreating):

```bash
docker compose up -d playit
```

Your server is now reachable at the address shown in the playit dashboard — no port forwarding or DNS configuration needed.

### 5. Whitelist players

Add player UUIDs (comma-separated) to `MC_WHITELIST` and `MC_OPS` in `.env`, then apply it (a plain `restart` won't pick up the new values — the container needs recreating):

```bash
docker compose up -d mc
```

Or manage in-game via RCON:

```bash
docker compose exec mc rcon-cli
```

## Scripts

Utility scripts live in `scripts/`.

**`setup_master.sh`** — main setup script; run this first.

```bash
./scripts/setup_master.sh
```

**`auto_configure.sh`** — selects the correct Java image and JVM flags for a given Minecraft version.

```bash
MC_VERSION=1.21.1 ./scripts/auto_configure.sh
```

**`server_status_mac.sh` / `server_status_linux.sh`** — start, stop, and check server status. `setup_master.sh` can configure an `mcserver` alias for these.

```bash
mcserver start
mcserver stop
mcserver status
```

## Data

Server world data and backups are stored at:

```
/Volumes/Storage/Server/MC/
├── data/     # world, plugins, configs
└── backups/  # automated backups via the mc-backup sidecar container
```

These paths can be overridden in `.env` via `MC_DATA_DIR` and `MC_BACKUP_DIR`.

## ☕ Support

If you found this useful, consider [buying me a ko-fi](https://ko-fi.com/ewancroft)!
