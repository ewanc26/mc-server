# Maintenance

## Updating the Server

```bash
docker compose down
# Edit VERSION in compose.yml
docker compose up -d
````

## Plugin Management

* Update `SPIGET_RESOURCES` or `PLUGINS` in `compose.yml`
* Or place `.jar` files into `./data/plugins` and:

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
