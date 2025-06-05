# Usage

## Starting the Server

```bash
docker compose up -d
```

## Viewing Logs

```bash
docker compose logs -f mc
```

## Stopping the Server

```bash
docker compose down
```

## Accessing the Console

```bash
docker compose exec mc rcon-cli
```

Type `exit` to leave the console.

## Whitelisting / Operator Permissions

Set `OPS` in `compose.yml`, or use:

```bash
docker compose exec mc rcon-cli op <username>
```

Use `whitelist add <username>` if the whitelist is enabled.
