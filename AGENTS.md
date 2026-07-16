# AGENTS.md

Guidance for agents working on this Docker Compose PaperMC server and its host-setup scripts.

## Runtime map

- `compose.yml` defines `mc`, `backups`, and host-networked `playit` services. Minecraft, RCON, voice, Bedrock, and Chronicler ports bind to loopback; public ingress is expected through playit.
- Persistent defaults are macOS-specific `/Volumes/Storage/Server/MC/{data,backups,sysinfo}` bind mounts. `.env` overrides almost every setting and is the actual deployment configuration.
- `scripts/setup_master.sh` is an interactive mutating installer; it sources `lib/` helpers, may edit `.env`/`compose.yml`/shell profiles, install host packages, start containers, and launch the Minefetch watcher.
- `scripts/auto_configure.sh` only upserts Java image tag, Minecraft version, JVM flags, and optionally memory/performance keys in `.env`. `detect_hardware.sh` instead generates a whole env file.
- `scripts/sync_from_server.sh` reads live whitelist/ops (optionally ban) JSON, writes `.env` and tracked Compose defaults, and can commit `compose.yml`. Status, DuckDNS, Minefetch, and setup scripts also mutate host/container services.
- `docs/` is the operator runbook; compare it with current Compose and scripts rather than assuming older examples are authoritative.

## Current hazards and invariants

- Do not run setup, lifecycle, sync, DuckDNS, package-install, or Compose commands as validation. They can stop the live server, install software, edit cron/launchd and shell profiles, expose a tunnel, commit runtime data, or alter `/Volumes/Storage/Server/MC`.
- `MC_VERSION=26.1.2` uses Paper's newer calendar-style numbering. `auto_configure.sh` compares it with legacy `1.x` thresholds and currently classifies it as “1.22+”, selecting `java21`, while Compose/`.env.example` default to `java25`. Update version mapping deliberately and test both numbering schemes.
- Compose defaults currently contain concrete whitelist/operator UUIDs and default `EULA` to true. Do not add or refresh player UUIDs, names, IP bans, tokens, or other live state in tracked files. In particular, `sync_from_server.sh` is designed to copy those values into `compose.yml`; use only an explicitly approved sanitized workflow.
- The backup sidecar requires RCON credentials and assumes RCON is enabled; `.env.example` does so, while raw Compose defaults disable RCON and require a non-empty backup password. `docker compose config` without a properly configured `.env` is not proof that backups can run.
- `lib/backup.sh` is an online recursive copy with no server stop, save flush, snapshot, integrity check, or restore test. It is distinct from the `mc-backup` sidecar and must not be described as a consistent world backup.
- `setup_master.sh`'s maximum-efficiency option edits tracked `compose.yml`; Minefetch setup relies on the sibling `minefetch` checkout and a background watcher; alias setup appends to a user shell profile. Keep these actions explicit and idempotent.
- DuckDNS is legacy beside playit and writes tokens into user-home scripts/config, plus cron, launchd, or Homebrew services. Do not invoke or expand it unless DuckDNS is explicitly in scope.
- `playit` uses host networking while the instructions sometimes say to target Compose hostname `mc:25565`; host-networked agents generally need the host/loopback-published port, so verify the actual agent/tunnel topology before changing public routing.
- Preserve world data and obtain an application-consistent, verified backup before any version, plugin, container, or destructive lifecycle change. Never commit `.env`, RCON/playit/DuckDNS secrets, worlds, logs, plugin databases, or archives.

## Validation

Run `bash -n run_config.sh lib/*.sh scripts/*.sh` and `shellcheck` on changed shell files. With a sanitized temporary env, run `docker compose config --quiet` and inspect the fully rendered mounts, ports, RCON coupling, images, and resource limits; do not use the production `.env`. Unit-test version selection and env/Compose rewriting against temporary copies, including calendar-style versions, spaces, empty lists, malformed JSON, and dry-run immutability. For a live deployment change, separately verify clean save/stop/start, health, backup checksum and disposable restore, playit reachability, whitelist/ops, RCON isolation, Bedrock/voice routes, and rollback.
