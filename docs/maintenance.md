# Maintenance

## Updating the Server

```bash
docker compose down
# Edit VERSION in compose.yml
docker compose up -d
````

## Plugin Management

* Update `SPIGET_RESOURCES` (for SpigotMC resource IDs like ProtocolLib (ID 1997), PlayerHealthDisplay (ID 125742), ViaVersionStatus (ID 66959), ViaBackwards (ID 27448), ViaVersion (ID 19254), minefetch (ID 113050)) or `PLUGINS` in `compose.yml`
* Or place `.jar` files into `./data/minecraft/plugins` and:

```bash
docker compose restart mc
```

## Backups

```bash
docker compose down
chmod +x backup_minecraft.sh
./backup_minecraft.sh
docker compose up -d
```
