# Uptime Kuma

Uptime Kuma is a self-hosted monitoring tool that tracks service uptime and sends alerts when endpoints go down. Supports HTTP, TCP, DNS, Docker, and ping monitors with notification channels including Discord, email, Slack, and Telegram.

## Access

- Private hostname: `status.${DOMAIN_ROOT}`
- Internal upstream: `uptime-kuma:3001`
- Scheme: `http`

## Compose Location

```text
docker-compose/uptime-kuma/docker-compose.yml
```

## Storage

| Path | Purpose |
| --- | --- |
| `/mnt/ssd/docker-volumes/uptime-kuma/data` | Persistent data (SQLite database, monitor configs, notification settings) |

Important: the data directory must be on a local filesystem. NFS or network-backed storage risks SQLite corruption due to file locking issues.

## NPM Proxy Host

| Field | Value |
| --- | --- |
| Domain | `status.homelab.ansh-info.com` |
| Scheme | `http` |
| Forward Hostname | `uptime-kuma` |
| Forward Port | `3001` |
| Cache Assets | enabled |
| Block Common Exploits | enabled |
| Websockets Support | enabled (required - app is WebSocket-based) |
| Force SSL | enabled |
| HTTP/2 Support | enabled |
| HSTS Enabled | enabled |
| HSTS Sub-domains | enabled |
| SSL Certificate | `*.homelab.ansh-info.com` wildcard |

Websockets Support is critical for Uptime Kuma. The app uses WebSocket connections for real-time status updates. Without this toggle, the UI will fail to load or show stale data.

## Deployment

Deploy via Portainer using the compose file. No additional environment file is needed.

### Host preparation

```bash
sudo mkdir -p /mnt/ssd/docker-volumes/uptime-kuma/data
```

### Portainer deployment

1. Create a new stack named `uptime-kuma`
2. Paste the compose file contents or point to the git repo path
3. Deploy

### CLI fallback

```bash
cd docker-compose/uptime-kuma
docker compose up -d
```

## Post-Deployment Setup

1. Visit `status.${DOMAIN_ROOT}` after deployment
2. Create an admin account (first visit only)
3. Add monitors for each homelab service:
   - Pi-hole: HTTP `http://pihole:80/admin/`
   - NPM: HTTP `http://nginx-proxy-manager:81`
   - Jellyfin: HTTP `http://jellyfin:8096`
   - Immich: HTTP `http://immich_server:2283`
   - Actual Budget: HTTP `http://actual-budget:5006`
   - OpenClaw: HTTP `http://openclaw-gateway:18789/healthz`
4. Configure notification channels (Discord webhook, email, etc.)

All monitors use internal container hostnames since Uptime Kuma is on the same `proxy` network.

## Verification

```bash
# Container health
docker ps --filter name=uptime-kuma

# Network membership
docker network inspect proxy | grep uptime-kuma

# DNS resolution (from tailnet client)
dig +short status.${DOMAIN_ROOT} @${TAILSCALE_IP}

# Proxy routing
curl -vk --resolve status.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://status.${DOMAIN_ROOT}/
```

## Updates

Watchtower will auto-update this container. For manual updates:

```bash
docker compose pull && docker compose up -d
```

## Backup

Back up the data directory:

```bash
/mnt/ssd/docker-volumes/uptime-kuma/data
```

Contains the SQLite database with all monitor configurations, history, and notification settings.

## Related Docs

- [NETWORKING.md](../NETWORKING.md)
- [VARIABLES.md](../VARIABLES.md)
- [OPERATIONS.md](../OPERATIONS.md)
- [nginx-proxy-manager.md](nginx-proxy-manager.md)
