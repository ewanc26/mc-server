# Troubleshooting

## Server not starting

Check the logs:

```bash
docker compose logs mc
```

Common causes:

- `MC_VERSION` not set in `.env` — the server will refuse to start without it
- EULA not accepted — ensure `MC_EULA=TRUE` in `.env`
- Docker not running — start Docker Desktop or OrbStack first
- Port conflict on `127.0.0.1:25565` — check if something else is using that port locally

## Players can't connect

- Check the playit dashboard at <https://playit.gg/account/tunnels> — confirm the tunnel is active and the address is correct
- Confirm the playit agent is running: `docker compose logs playit`
- If `PLAYIT_SECRET` is missing from `.env`, the agent won't start a tunnel — see [getting-started.md](getting-started.md) step 5
- Confirm the player's UUID is in `MC_WHITELIST` in `.env`
- Ensure the Minecraft client version matches `MC_VERSION` (or that ViaVersion is active for cross-version support)

## Tunnel not working

```bash
docker compose restart playit
docker compose logs playit
```

If the agent prints a claim URL, your secret has expired or was never set. Re-claim:

1. Open the URL in the logs
2. Reconfigure the tunnel in the playit dashboard
3. Update `PLAYIT_SECRET` in `.env`
4. `docker compose restart playit`

## Plugins failing

Check server logs for compatibility errors:

```bash
docker compose logs mc | grep -i "error\|warn\|plugin"
```

- Ensure the plugin version supports your `MC_VERSION`
- Re-run `auto_configure.sh` to reset to known-compatible versions

## Performance issues

```bash
docker stats mc
```

In-game, run `/spark profiler start` and check the report for bottlenecks. Lower `MC_VIEW_DISTANCE` or `MC_SIMULATION_DISTANCE` in `.env` if TPS is consistently below 20.
