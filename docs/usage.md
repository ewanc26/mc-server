# Usage

## Starting the Server

```bash
docker compose up -d
```

This starts both the Minecraft server (`mc`) and the playit tunnel agent (`playit`).

## Viewing Logs

```bash
# Minecraft server
docker compose logs -f mc

# playit agent
docker compose logs -f playit
```

## Stopping the Server

```bash
docker compose down
```

## Accessing the Console

```bash
docker compose exec mc rcon-cli
```

Type `exit` to leave.

## Origins

The server runs Origins-Reborn with all expansions (Mobs, Monsters, Fantasy, Magic). On first join, you'll pick an origin that grants unique abilities and drawbacks.

- **Change origin on death** — enabled. If your origin isn't working out, you'll get a new pick when you respawn.
- **Orb of Origin** — craftable with a Nether Star surrounded by Diamonds to switch origins at will.
- **Admins** can use `/origin swap` to switch freely.

## Whitelisting and Operator Permissions

Set `MC_WHITELIST` and `MC_OPS` in `.env` (comma-separated UUIDs), then apply it (a plain `restart` won't pick up the new values — the container needs recreating):

```bash
docker compose up -d mc
```

Or manage live via the console:

```bash
docker compose exec mc rcon-cli
# then:
whitelist add <username>
op <username>
```

## Checking Server Performance

```bash
docker stats mc
```

In-game:

```
/tps          — current TPS
/spark profiler start — profile for 60s then generate report
/minefetch    — system info
/loadfetch    — CPU/RAM graphs
```
