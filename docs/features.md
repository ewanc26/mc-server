# Features

- **Personal use optimised:** Configured for small groups of friends, balancing performance and ease of management.
- **PaperMC:** Performance-optimised server with plugin support.
- **Dockerised:** Consistent environment across macOS and Linux via Docker Compose.
- **Environment-driven config:** All settings controlled through `.env` — no need to edit `compose.yml` directly.
- **Persistent data:** World data, plugins, and configs stored at `/Volumes/Storage/Server/MC/data`. Backups at `/Volumes/Storage/Server/MC/backups`.
- **Public access via playit.gg:** Tunnelled connection with no port forwarding or router configuration required.
- **Automatic backups:** Managed by the `mc-backup` sidecar container (via RCON) — runs every 6h with 7-day retention.
- **Performance plugins:** Spark for profiling, Minefetch for in-game system stats.
