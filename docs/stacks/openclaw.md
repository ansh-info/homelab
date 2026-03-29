# OpenClaw Stack

This guide documents the OpenClaw deployment in the homelab, including the exact first-run bootstrap needed for the containerized gateway, the private NPM exposure model, Discord DM onboarding, OpenAI model auth, and the main failure modes discovered during the initial rollout.

For the shared placeholder vocabulary used in this file, see [../VARIABLES.md](../VARIABLES.md).

Reference files:

- [docker-compose/openclaw/docker-compose.yml](../../docker-compose/openclaw/docker-compose.yml)
- [docker-compose/openclaw/stack.env](../../docker-compose/openclaw/stack.env)

## Purpose

OpenClaw provides a private, always-on personal AI assistant gateway in the homelab.

The current working rollout includes:

- the OpenClaw gateway
- the Gateway-served web UI
- private HTTPS access through `${OPENCLAW_HOSTNAME}`
- Discord direct-message integration
- OpenAI API-key model auth

The current recommended working model is:

- `openai/gpt-5.4-mini`

This keeps costs lower while the stack is still being validated. A stronger upgrade path later is:

- `openai/gpt-5.4`

## Dependencies

- Docker and Portainer
- the shared Docker network `${PROXY_NETWORK}`
- Pi-hole DNS for `${OPENCLAW_HOSTNAME}`
- Nginx Proxy Manager for private HTTPS routing
- persistent host paths under `${OPENCLAW_DATA_ROOT}`
- valid `OPENCLAW_GATEWAY_TOKEN`
- valid `DISCORD_BOT_TOKEN` for Discord DM support
- valid `OPENAI_API_KEY` for the current OpenAI-backed model path

## Current Example Values

```text
${OPENCLAW_DATA_ROOT}=/mnt/ssd/docker-volumes/openclaw
${OPENCLAW_CONFIG_ROOT}=/mnt/ssd/docker-volumes/openclaw/config
${OPENCLAW_WORKSPACE_ROOT}=/mnt/ssd/docker-volumes/openclaw/workspace
${OPENCLAW_TZ}=Asia/Kolkata
${OPENCLAW_HOSTNAME}=openclaw.homelab.ansh-info.com
${OPENCLAW_GATEWAY_PORT}=18789
```

## Storage Paths

OpenClaw uses a dedicated host storage root:

- `${OPENCLAW_DATA_ROOT}`

Current mounted paths:

- `${OPENCLAW_CONFIG_ROOT}` -> `/home/node/.openclaw`
- `${OPENCLAW_WORKSPACE_ROOT}` -> `/home/node/.openclaw/workspace`

The container expects uid/gid `1000:1000` ownership for these paths.

Prepare them on the host with:

```bash
sudo mkdir -p ${OPENCLAW_CONFIG_ROOT}
sudo mkdir -p ${OPENCLAW_WORKSPACE_ROOT}
sudo chown -R 1000:1000 ${OPENCLAW_DATA_ROOT}
```

## Compose Highlights

- service: `openclaw-gateway`
- image: `ghcr.io/openclaw/openclaw:latest`
- attached to `${PROXY_NETWORK}`
- no routine host port publishing in the homelab pattern
- persistent mounts:
  - `${OPENCLAW_CONFIG_ROOT}:/home/node/.openclaw`
  - `${OPENCLAW_WORKSPACE_ROOT}:/home/node/.openclaw/workspace`
- required env:
  - `OPENCLAW_GATEWAY_TOKEN`
- optional env consumed by the stack:
  - `DISCORD_BOT_TOKEN`
  - `OPENAI_API_KEY`
  - `OPENCLAW_TZ`

## Portainer Env Contract

Enter these values through the Portainer stack environment UI when deploying the stack:

- `OPENCLAW_GATEWAY_TOKEN`
  - required
  - use a long random token
  - generate with:
    - `openssl rand -hex 32`
- `DISCORD_BOT_TOKEN`
  - required for the working Discord DM rollout
  - comes from the Discord Developer Portal bot page
- `OPENAI_API_KEY`
  - required for the current working OpenAI model path
  - comes from the OpenAI Platform dashboard
- `OPENCLAW_TZ`
  - optional
  - defaults to `Asia/Kolkata` in the checked-in compose file

Do not commit live tokens into git. Treat the Portainer env values as operational secrets.

## First Deployment

Use this order for the first successful Portainer deployment.

### 1. Prepare host paths

Run on the host:

```bash
sudo mkdir -p ${OPENCLAW_CONFIG_ROOT}
sudo mkdir -p ${OPENCLAW_WORKSPACE_ROOT}
sudo chown -R 1000:1000 ${OPENCLAW_DATA_ROOT}
```

### 2. Deploy the stack in Portainer

In Portainer:

1. create or update stack `openclaw`
2. paste the compose from `docker-compose/openclaw/docker-compose.yml`
3. set the required env values:
   - `OPENCLAW_GATEWAY_TOKEN`
   - `DISCORD_BOT_TOKEN`
   - `OPENAI_API_KEY`
   - `OPENCLAW_TZ` if overriding the default
4. deploy the stack

### 3. Bootstrap the OpenClaw runtime

The first deployment will fail if `${OPENCLAW_CONFIG_ROOT}` exists but has not been initialized yet.

Run these commands on the host:

```bash
docker stop openclaw-gateway
```

```bash
docker run --rm \
  -v ${OPENCLAW_CONFIG_ROOT}:/home/node/.openclaw \
  -v ${OPENCLAW_WORKSPACE_ROOT}:/home/node/.openclaw/workspace \
  ghcr.io/openclaw/openclaw:latest \
  node dist/index.js setup --workspace /home/node/.openclaw/workspace
```

```bash
docker run --rm \
  -v ${OPENCLAW_CONFIG_ROOT}:/home/node/.openclaw \
  -v ${OPENCLAW_WORKSPACE_ROOT}:/home/node/.openclaw/workspace \
  ghcr.io/openclaw/openclaw:latest \
  node dist/index.js config set gateway.mode local
```

```bash
docker run --rm \
  -v ${OPENCLAW_CONFIG_ROOT}:/home/node/.openclaw \
  -v ${OPENCLAW_WORKSPACE_ROOT}:/home/node/.openclaw/workspace \
  ghcr.io/openclaw/openclaw:latest \
  node dist/index.js config set gateway.bind lan
```

```bash
docker run --rm \
  -v ${OPENCLAW_CONFIG_ROOT}:/home/node/.openclaw \
  -v ${OPENCLAW_WORKSPACE_ROOT}:/home/node/.openclaw/workspace \
  ghcr.io/openclaw/openclaw:latest \
  node dist/index.js config set gateway.controlUi.allowedOrigins \
  '["https://${OPENCLAW_HOSTNAME}"]' --strict-json
```

Then restart the container:

```bash
docker start openclaw-gateway
```

### 4. Verify the container is healthy

Run:

```bash
docker ps --filter name=openclaw-gateway
docker logs --tail 100 openclaw-gateway
docker inspect --format='{{json .State.Health}}' openclaw-gateway
```

The container should become `healthy`.

Important:

- the repo documents the infrastructure shape
- the live OpenClaw runtime config remains under `/home/node/.openclaw`
- Discord onboarding state is runtime data and must be preserved during rebuilds

## NPM Proxy Target

Use this proxy-host entry:

| Public hostname | Scheme | Forward Hostname / IP | Forward Port |
| --- | --- | --- | --- |
| `${OPENCLAW_HOSTNAME}` | `http` | `openclaw-gateway` | `${OPENCLAW_GATEWAY_PORT}` |

Recommended NPM toggles:

- `Access List`: `Publicly Accessible`
- `Cache Assets`: enabled
- `Block Common Exploits`: enabled
- `Websockets Support`: enabled
- SSL certificate: `*.${DOMAIN_ROOT}`
- `Force SSL`: enabled
- `HTTP/2 Support`: enabled
- `HSTS Enabled`: enabled
- `HSTS Sub-domains`: enabled

## Control UI Pairing

The browser-based Control UI is not ready immediately after the first successful gateway start.

Expected flow:

1. Open `https://${OPENCLAW_HOSTNAME}`
2. Paste the value of `OPENCLAW_GATEWAY_TOKEN` into the Control UI settings
3. The gateway may still reject the browser with `pairing required`
4. Approve the browser/device with:

```bash
docker exec openclaw-gateway node dist/index.js devices list
docker exec openclaw-gateway node dist/index.js devices approve <request-id>
```

5. Reload the Control UI

After approval, the browser should connect normally.

## Discord Setup

OpenClaw Discord support in this homelab is currently DM-first.

### Discord application and bot

In the Discord Developer Portal:

1. create a new application
2. open `Bot`
3. create the bot
4. copy the bot token into `DISCORD_BOT_TOKEN`

### Required intents

In `Bot` -> `Privileged Gateway Intents`, enable:

- `Message Content Intent`
- `Server Members Intent` recommended
- `Presence Intent` optional

Without `Message Content Intent`, OpenClaw logs a Discord `4014` error and the bot will not function correctly.

### Invite scopes and permissions

In `OAuth2` -> `URL Generator`, enable:

- `bot`
- `applications.commands`

Bot permissions:

- `View Channels`
- `Send Messages`
- `Read Message History`
- `Embed Links`
- `Attach Files`
- `Add Reactions` optional

Invite the bot to a private server that you control.

### Enable DMs

In Discord, allow DMs from server members for the server where the bot is installed. This lets the bot DM you for pairing.

### DM pairing

DM the bot.

The first response should contain a pairing code. Approve it with:

```bash
docker exec openclaw-gateway node dist/index.js pairing list discord
docker exec openclaw-gateway node dist/index.js pairing approve discord <CODE>
```

After approval, Discord DMs should work normally.

## Model and Provider Setup

The current working deployment uses OpenAI API-key auth.

### 1. Set the OpenAI API key

Add `OPENAI_API_KEY` in the Portainer stack env and redeploy the stack.

### 2. Set the default model

The current recommended working model is:

- `openai/gpt-5.4-mini`

Set it with:

```bash
docker exec openclaw-gateway node dist/index.js models set openai/gpt-5.4-mini
```

Verify the current model/auth state with:

```bash
docker exec openclaw-gateway node dist/index.js models status
```

### 3. Stronger model option later

If you want a stronger model later, switch to:

```bash
docker exec openclaw-gateway node dist/index.js models set openai/gpt-5.4
```

## Backup Targets

Back up these paths first:

- `${OPENCLAW_CONFIG_ROOT}`
- `${OPENCLAW_WORKSPACE_ROOT}`

These paths contain:

- runtime config
- device/browser pairing state
- Discord pairing and allowlist state
- agent workspace and session data

## Recovery

For recovery or redeploy:

1. preserve `${OPENCLAW_CONFIG_ROOT}` and `${OPENCLAW_WORKSPACE_ROOT}`
2. confirm the `proxy` network exists before redeploying
3. re-enter the required Portainer env values if the stack definition was recreated
4. redeploy the stack through Portainer
5. restore the OpenClaw bootstrap settings if the config was lost:
   - `gateway.mode local`
   - `gateway.bind lan`
   - `gateway.controlUi.allowedOrigins`
6. confirm container health
7. confirm NPM can still reach `openclaw-gateway:${OPENCLAW_GATEWAY_PORT}`
8. confirm private HTTPS access through `${OPENCLAW_HOSTNAME}`
9. confirm Discord connectivity and pairing state
10. confirm the model is still set to the intended provider/model

If the runtime state under `${OPENCLAW_CONFIG_ROOT}` is lost, expect to re-do:

- OpenClaw setup/bootstrap
- Control UI device pairing
- Discord DM pairing
- model/provider selection

## Verification

### Compose and container

```bash
OPENCLAW_GATEWAY_TOKEN=placeholder docker compose -f docker-compose/openclaw/docker-compose.yml config
docker ps --filter name=openclaw-gateway
docker logs --tail 100 openclaw-gateway
docker inspect --format='{{json .State.Health}}' openclaw-gateway
docker network inspect proxy
```

### Private HTTPS path

```bash
dig +short ${OPENCLAW_HOSTNAME} @${TAILSCALE_IP}
curl -vk --resolve ${OPENCLAW_HOSTNAME}:443:${TAILSCALE_IP} https://${OPENCLAW_HOSTNAME}/
```

### Device pairing state

```bash
docker exec openclaw-gateway node dist/index.js devices list
```

### Discord pairing state

```bash
docker exec openclaw-gateway node dist/index.js pairing list discord
```

### Model/auth state

```bash
docker exec openclaw-gateway node dist/index.js models status
```

## Troubleshooting

### `Missing config. Run openclaw setup...`

Cause:

- the mounted OpenClaw config directory exists, but runtime initialization has not happened yet

Fix:

1. run `setup`
2. set `gateway.mode local`
3. set `gateway.bind lan`
4. set `gateway.controlUi.allowedOrigins`
5. restart the container

### `token_missing` in the Control UI logs

Cause:

- the gateway token has not been entered into the browser UI

Fix:

- open the Control UI settings
- paste the configured `OPENCLAW_GATEWAY_TOKEN`

### `pairing required` in the Control UI logs

Cause:

- the browser/device has not been approved yet

Fix:

```bash
docker exec openclaw-gateway node dist/index.js devices list
docker exec openclaw-gateway node dist/index.js devices approve <request-id>
```

### Discord `4014` / missing privileged intents

Cause:

- `Message Content Intent` was not enabled in the Discord Developer Portal

Fix:

- enable `Message Content Intent`
- restart `openclaw-gateway`

### `No API key found for provider "anthropic"`

Cause:

- OpenClaw was still using an Anthropic default model while only OpenAI credentials were configured

Fix:

1. add `OPENAI_API_KEY` in Portainer
2. redeploy the stack
3. set:

```bash
docker exec openclaw-gateway node dist/index.js models set openai/gpt-5.4-mini
```

### Proxy warning about untrusted headers

Log example:

- `Proxy headers detected from untrusted address...`

Cause:

- OpenClaw does not yet trust the reverse proxy for local-client detection

Impact:

- warning only in the current working deployment
- not a blocker for token-authenticated private use through NPM

Action:

- safe to leave as-is for now
- only tune `gateway.trustedProxies` later if you specifically need trusted-proxy behavior
