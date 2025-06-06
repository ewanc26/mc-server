# Maintenance

## Updating the Server

```bash
docker compose down
# Edit VERSION in compose.yml
docker compose up -d
````

## Plugin Management

* Update `SPIGET_RESOURCES` (for SpigotMC resource IDs like ProtocolLib (ID 1997)) or `PLUGINS` (for direct URLs like TCPShield RealIP, Backuper, Headstones) in `compose.yml`
* Or place `.jar` files into `./data/minecraft/plugins` and:

```bash
docker compose restart mc
```
