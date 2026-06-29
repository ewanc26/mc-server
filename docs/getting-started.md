# Getting Started

## Prerequisites

- [System requirements](system-requirements.md) met.
- A [playit.gg](https://playit.gg) account.

## Setup

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

- `MC_VERSION` — Minecraft version to run (e.g. `1.21.1`)
- `MC_WHITELIST` — comma-separated player UUIDs
- `MC_OPS` — comma-separated operator UUIDs

Leave `PLAYIT_SECRET` blank for now.

### 3. Run auto-configuration

Selects the correct Java image and JVM flags for your chosen version. Plugins aren't part of this step — they're managed separately via `MC_MODRINTH_PROJECTS` / `MC_SPIGET_RESOURCES` in `.env`:

```bash
MC_VERSION=1.21.1 ./scripts/auto_configure.sh
```

### 4. Start the server

```bash
docker compose up -d
```

### 5. Claim the playit.gg tunnel

On first run the playit agent prints a claim URL. Retrieve it:

```bash
docker compose logs playit
```

Open the URL, sign in, and add a **Minecraft** tunnel pointed at `mc:25565`. Copy the secret key from the dashboard and add it to `.env`:

```
PLAYIT_SECRET=your_secret_here
```

Then apply it (a plain `restart` won't pick up the new secret — the container needs recreating):

```bash
docker compose up -d playit
```

Your server address is shown in the playit dashboard. Share it with whitelisted players.

### 6. (Optional) Set up Bedrock access

See the [playit.gg Tunnel Setup](./docs/playit.md#bedrock-geyser-tunnel) doc for Bedrock tunnel configuration and account-linking instructions.

### 7. (Optional) Run the setup script

For a guided setup including optimisation prompts, neofetch installation, and alias configuration:

```bash
./scripts/setup_master.sh
```
