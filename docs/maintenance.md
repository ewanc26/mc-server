# Maintenance

## Updating the Minecraft Version

Update `MC_VERSION` in `.env`, then re-run auto-configuration and restart:

```bash
MC_VERSION=1.21.4 ./scripts/auto_configure.sh
docker compose down
docker compose up -d
```

## Updating the Server Image

```bash
docker compose pull
docker compose down
docker compose up -d
```

## Plugin Management

Plugins are configured directly in `.env` via two variables — `scripts/auto_configure.sh` doesn't touch either of these; it only sets the Java image, `MC_VERSION`, and JVM flags:

- `MC_MODRINTH_PROJECTS` — comma-separated Modrinth slugs (e.g. `luckperms,coreprotect`). The image auto-resolves the correct build for the running loader and `MC_VERSION` on every container start. Append `?` to a slug (e.g. `bluemap?`) to mark it optional, so a missing build for your version logs a warning instead of failing the whole startup.
- `MC_SPIGET_RESOURCES` — SpigotMC resource IDs (e.g. `1997` for ProtocolLib), downloaded via Spiget.

To add a plugin, append its slug (or resource ID) to the relevant variable in `.env` and apply it (a plain `restart` won't pick up the new value — the container needs recreating):

```bash
docker compose up -d mc
```

Or drop a `.jar` directly into `/Volumes/Storage/Server/MC/data/plugins` and restart.

## Backups

Backups are written to `/Volumes/Storage/Server/MC/backups` by the `mc-backup` sidecar container automatically (every 6h, 7-day retention, via RCON — see the `backups` service in `compose.yml`). Backups pause while no players are online (`PAUSE_IF_NO_PLAYERS`), since nothing in the world can change with nobody there — it rechecks every `PLAYERS_ONLINE_CHECK_INTERVAL` (5m by default) and resumes the normal cadence once someone joins.

For a manual snapshot before making changes, the setup script can create one:

```bash
./scripts/setup_master.sh
```

Or copy the data directory yourself:

```bash
cp -r /Volumes/Storage/Server/MC/data /Volumes/Storage/Server/MC/backups/manual_$(date +%Y%m%d)
```
