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

Plugins are configured in `.env` via two variables:

- `MC_SPIGET_RESOURCES` — SpigotMC resource IDs (e.g. `1997` for ProtocolLib)
- `MC_PLUGINS` — direct download URLs for plugin JARs

The auto-configuration script (`scripts/auto_configure.sh`) sets these for the selected Minecraft version. To add a plugin manually, append its URL to `MC_PLUGINS` in `.env` and restart:

```bash
docker compose restart mc
```

Or drop a `.jar` directly into `/Volumes/Storage/Server/MC/data/plugins` and restart.

## Backups

Backups are written to `/Volumes/Storage/Server/MC/backups` by the Backuper plugin automatically.

For a manual snapshot before making changes, the setup script can create one:

```bash
./scripts/setup_master.sh
```

Or copy the data directory yourself:

```bash
cp -r /Volumes/Storage/Server/MC/data /Volumes/Storage/Server/MC/backups/manual_$(date +%Y%m%d)
```
