# playit.gg Tunnel Setup

[playit.gg](https://playit.gg) provides a free persistent tunnel to your Minecraft server with no port forwarding or router configuration required.

## First-time setup

### 1. Start the playit agent

If `PLAYIT_SECRET` is not yet set in `.env`, start just the agent:

```bash
docker compose up -d playit
```

### 2. Retrieve the claim URL

```bash
docker compose logs playit
```

Look for a line containing `https://playit.gg/claim/...` and open it in your browser.

### 3. Configure the tunnel

Sign into playit.gg and add a tunnel with these settings:

- **Type:** Minecraft Java
- **Local address:** `mc:25565`

### 4. Add the secret to `.env`

Copy the secret key from the playit dashboard and add it:

```
PLAYIT_SECRET=your_secret_here
```

### 5. Restart the agent

```bash
docker compose restart playit
```

The tunnel address is shown in the playit dashboard — share it with whitelisted players.

## Reclaiming a lost or expired secret

If the agent can't connect, re-run the first-time setup flow:

1. Remove `PLAYIT_SECRET` from `.env` (or leave it blank)
2. `docker compose restart playit`
3. Check `docker compose logs playit` for a new claim URL
4. Update `PLAYIT_SECRET` in `.env` and restart again

## Custom domain

playit.gg supports custom domains on paid plans. Configure these in the playit dashboard — no changes needed in `.env` or `compose.yml`.

## Bedrock (Geyser) tunnel

Bedrock Edition players need a second, separate tunnel — playit's **Minecraft Bedrock** type, which is UDP rather than Java's TCP. This needs Geyser/Floodgate installed via `MC_PLUGINS` in `.env` (see `.env.example`) and port `19132/udp` exposed, which `compose.yml` already handles through `MC_BEDROCK_PORT`.

### Setup

1. In the playit dashboard, add a tunnel with these settings:
   - **Type:** Minecraft Bedrock
   - **Local address:** `mc:19132`
   - **Proxy Protocol:** proxy-protocol-v2
2. On the host, open Geyser's config (`<data-dir>/plugins/Geyser-Spigot/config.yml`) and under `advanced: bedrock:`, set:
   ```yaml
   use-haproxy-protocol: true
   broadcast-port: <tunnel port>
   ```
   This lives in the data volume, outside this repo, so it has to be edited directly on the host.
3. Apply the plugin and port changes:
   ```bash
   docker compose up -d mc
   ```

### Current tunnel

```
meeting-hidden.gl.at.ply.gg:61768
```

Bedrock players connect with this address. `broadcast-port` in Geyser's `config.yml` should be set to `61768` to match. If the tunnel is ever recreated, the address changes and this needs updating.

### Linking accounts

Because the server uses a whitelist (Java UUIDs), Bedrock players must link their Bedrock and Java accounts so Floodgate can authorise them.

1. Have the player join the server once via **Java Edition** (their Java UUID must be in `MC_WHITELIST`).
2. In-game, run `/linkaccount` — a linking code is printed in chat.
3. Have them join again, this time via **Bedrock Edition**, and run `/linkaccount <code>`.
4. Done. Floodgate remembers the link and lets them in on future Bedrock connections.

Bedrock players appear with a `.` prefix on their username (e.g. `.Steve`) to avoid name collisions with Java players.
