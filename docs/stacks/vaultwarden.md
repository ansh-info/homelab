# Vaultwarden

Vaultwarden is a lightweight self-hosted Bitwarden-compatible password manager. Supports all Bitwarden clients (browser extensions, mobile apps, desktop apps) with a minimal resource footprint.

## Access

- Private hostname: `vault.${DOMAIN_ROOT}`
- Internal upstream: `vaultwarden:80`
- Scheme: `http`

## Compose Location

```text
docker-compose/vaultwarden/docker-compose.yml
```

## Storage

| Path | Purpose |
| --- | --- |
| `/mnt/ssd/docker-volumes/vaultwarden/data` | Persistent data (encrypted vault SQLite database, attachments, RSA keys, icon cache) |

## NPM Proxy Host

| Field | Value |
| --- | --- |
| Domain | `vault.homelab.ansh-info.com` |
| Scheme | `http` |
| Forward Hostname | `vaultwarden` |
| Forward Port | `80` |
| Cache Assets | enabled |
| Block Common Exploits | enabled |
| Websockets Support | enabled |
| Force SSL | enabled |
| HTTP/2 Support | enabled |
| HSTS Enabled | enabled |
| HSTS Sub-domains | enabled |
| SSL Certificate | `*.homelab.ansh-info.com` wildcard |

## Environment Variables

| Variable | Value | Purpose |
| --- | --- | --- |
| `DOMAIN` | `https://vault.homelab.ansh-info.com` | Required for attachment URLs and WebSocket notifications |
| `SIGNUPS_ALLOWED` | `false` | Disable public registration after initial account creation |

## Deployment

Deploy via Portainer using the compose file. No additional environment file is needed.

### Host preparation

```bash
sudo mkdir -p /mnt/ssd/docker-volumes/vaultwarden/data
```

### First deployment (signups enabled)

For the initial deployment, temporarily set `SIGNUPS_ALLOWED: "true"` in the compose file or Portainer env override. Create your account, then set it back to `"false"` and redeploy.

### Portainer deployment

1. Create a new stack named `vaultwarden`
2. Paste the compose file contents or point to the git repo path
3. Deploy
4. Create your account at `vault.${DOMAIN_ROOT}`
5. Redeploy with `SIGNUPS_ALLOWED: "false"` to lock registration

### CLI fallback

```bash
cd docker-compose/vaultwarden
docker compose up -d
```

## Client Setup

After deployment, connect Bitwarden clients:

1. Open any Bitwarden client (browser extension, mobile, desktop)
2. Before logging in, tap the gear icon or "Self-hosted"
3. Set server URL to `https://vault.homelab.ansh-info.com`
4. Log in with the account you created

Works with all official Bitwarden clients and third-party clients like Goldwarden.

## Verification

```bash
# Container health
docker ps --filter name=vaultwarden

# Network membership
docker network inspect proxy | grep vaultwarden

# DNS resolution (from tailnet client)
dig +short vault.${DOMAIN_ROOT} @${TAILSCALE_IP}

# Proxy routing
curl -vk --resolve vault.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://vault.${DOMAIN_ROOT}/
```

## Updates

Watchtower will auto-update this container. For manual updates:

```bash
docker compose pull && docker compose up -d
```

## Backup

Back up the data directory:

```bash
/mnt/ssd/docker-volumes/vaultwarden/data
```

Contains the encrypted SQLite database, RSA keys, and attachments. This is the single most critical backup target in the homelab - losing this means losing all passwords.

## Security Notes

- `SIGNUPS_ALLOWED` is `false` by default - only the initial admin can create accounts
- All vault data is encrypted client-side before reaching the server
- The `DOMAIN` variable must match the actual access URL for WebSocket push notifications to work
- Access is restricted to the tailnet via the standard Tailscale + Pi-hole + NPM path

## Related Docs

- [NETWORKING.md](../NETWORKING.md)
- [VARIABLES.md](../VARIABLES.md)
- [OPERATIONS.md](../OPERATIONS.md)
- [nginx-proxy-manager.md](nginx-proxy-manager.md)
