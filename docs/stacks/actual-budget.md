# Actual Budget

Actual Budget is a local-first personal finance tool with optional sync. It provides envelope budgeting, bank syncing, and reporting - all self-hosted.

## Access

- Private hostname: `actual.${DOMAIN_ROOT}`
- Internal upstream: `actual-budget:5006`
- Scheme: `http`

## Compose Location

```text
docker-compose/actual-budget/docker-compose.yml
```

## Storage

| Path | Purpose |
| --- | --- |
| `/mnt/ssd/docker-volumes/actual-budget/data` | Persistent data (server-files, user-files, SQLite databases) |

## NPM Proxy Host

| Field | Value |
| --- | --- |
| Domain | `actual.homelab.ansh-info.com` |
| Scheme | `http` |
| Forward Hostname | `actual-budget` |
| Forward Port | `5006` |
| Cache Assets | enabled |
| Block Common Exploits | enabled |
| Websockets Support | enabled |
| Force SSL | enabled |
| HTTP/2 Support | enabled |
| HSTS Enabled | enabled |
| HSTS Sub-domains | enabled |
| SSL Certificate | `*.homelab.ansh-info.com` wildcard |

## Deployment

Deploy via Portainer using the compose file. No additional environment file is needed.

### Host preparation

```bash
sudo mkdir -p /mnt/ssd/docker-volumes/actual-budget/data
```

### Portainer deployment

1. Create a new stack named `actual-budget`
2. Paste the compose file contents or point to the git repo path
3. Deploy

### CLI fallback

```bash
cd docker-compose/actual-budget
docker compose up -d
```

## Verification

```bash
# Container health
docker ps --filter name=actual-budget

# Network membership
docker network inspect proxy | grep actual-budget

# DNS resolution (from tailnet client)
dig +short actual.${DOMAIN_ROOT} @${TAILSCALE_IP}

# Proxy routing
curl -vk --resolve actual.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://actual.${DOMAIN_ROOT}/
```

## Updates

Watchtower will auto-update this container since it uses `latest-alpine`. For manual updates:

```bash
docker compose pull && docker compose up -d
```

## Backup

Back up the data directory:

```bash
/mnt/ssd/docker-volumes/actual-budget/data
```

This contains all budget files and user data. The SQLite databases inside are the primary state - no external database is needed.

## Related Docs

- [NETWORKING.md](../NETWORKING.md)
- [VARIABLES.md](../VARIABLES.md)
- [OPERATIONS.md](../OPERATIONS.md)
- [nginx-proxy-manager.md](nginx-proxy-manager.md)
