# AGENTS.md

Guidance for agents working on Ewan's Minecraft server automation repository.

## Repository model

- Root scripts coordinate setup and lifecycle.
- `scripts/` contains focused operational actions.
- `lib/` contains shared shell helpers; source these instead of copying logic.
- `docs/` is operator-facing runbook material and must match real commands.
- Runtime worlds, player data, secrets, logs, and server binaries are not source artifacts.

## Safety rules

- Make lifecycle operations idempotent and fail closed. Preserve traps that restore service state after partial failure.
- Quote every path/argument, validate required commands, and avoid `eval`.
- Never commit tokens, tunnel credentials, whitelist/private player data, server EULAs accepted on someone's behalf, or backups.
- Separate Java/Paper updates from configuration changes and preserve rollback instructions.
- Cross-play/tunnel changes affect external access; document ports, firewall expectations, and authentication impact.

## Validation

Run `shellcheck` on changed shell files and syntax-check with `bash -n`. Test helpers with temporary directories and dry-run/mocked service commands. For live changes verify start, stop, restart, crash recovery, tunnel state, whitelist behavior, permissions, and clean shutdown without risking the production world. Keep docs synchronized with exact paths and commands.
