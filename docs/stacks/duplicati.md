# Duplicati

Duplicati is a self-hosted backup tool with a web UI for scheduling encrypted, deduplicated backups to local or remote storage.

## Access

- Private hostname: `backup.${DOMAIN_ROOT}`
- Internal upstream: `duplicati:8200`
- Scheme: `http`

## Compose Location

```text
docker-compose/duplicati/docker-compose.yml
```

## Storage

| Path | Mount inside container | Purpose |
| --- | --- | --- |
| `/mnt/ssd/docker-volumes/duplicati/config` | `/config` | Duplicati configuration database and job definitions |
| `/mnt/backup` | `/backups` | Backup destination (HDD) |
| `/mnt/ssd/docker-volumes` | `/source` (read-only) | Source data to back up |

The source mount is read-only to prevent Duplicati from accidentally modifying service data.

## NPM Proxy Host

| Field | Value |
| --- | --- |
| Domain | `backup.homelab.ansh-info.com` |
| Scheme | `http` |
| Forward Hostname | `duplicati` |
| Forward Port | `8200` |
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
| `PUID` | `0` | Run as root to read all service volumes regardless of ownership |
| `PGID` | `0` | Run as root group |
| `TZ` | `Asia/Kolkata` | Timezone for scheduling |

Running as root is intentional here - Duplicati needs to read files owned by various service users (Nextcloud uses 33:33, others use different UIDs). The source mount is read-only as a safety net.

## Deployment

### Prerequisites

1. Backup HDD installed and mounted at `/mnt/backup`
2. Entry in `/etc/fstab` with `nofail` option (prevents boot failure if HDD is disconnected)

### Host preparation

```bash
# Format the backup HDD (verify device name first with lsblk!)
sudo mkfs.ext4 /dev/sdX1

# Create mount point
sudo mkdir -p /mnt/backup

# Get UUID
sudo blkid /dev/sdX1

# Add to /etc/fstab
# UUID=<your-uuid>  /mnt/backup  ext4  defaults,nofail  0  2

# Mount and create config directory
sudo mount -a
sudo mkdir -p /mnt/ssd/docker-volumes/duplicati/config
```

### Portainer deployment

1. Create a new stack named `duplicati`
2. Paste the compose file contents or point to the git repo path
3. Deploy

### CLI fallback

```bash
cd docker-compose/duplicati
docker compose up -d
```

## Post-Deployment Setup

### Recommended backup jobs

Create these backup jobs in the Duplicati web UI:

#### Job 1: Critical (daily)

- Source: `/source/vaultwarden`, `/source/pihole`, `/source/nginx-proxy-manager`, `/source/actual-budget`, `/source/uptime-kuma`
- Destination: `/backups/daily-critical`
- Schedule: Daily at 03:00
- Retention: Keep 7 daily + 4 weekly versions
- Encryption: AES-256 (set a passphrase you will remember)

#### Job 2: Media configs (weekly)

- Source: `/source/arr/radarr/config`, `/source/arr/sonarr/config`, `/source/arr/prowlarr/config`, `/source/arr/bazarr/config`, `/source/arr/qbittorrent`
- Destination: `/backups/weekly-configs`
- Schedule: Weekly Sunday 04:00
- Retention: Keep 4 weekly versions
- Encryption: AES-256

#### Job 3: Photos (weekly)

- Source: `/source/immich`
- Destination: `/backups/weekly-photos`
- Schedule: Weekly Sunday 05:00
- Retention: Keep 4 weekly versions
- Encryption: AES-256

#### Job 4: Cloud storage (weekly)

- Source: `/source/nextcloud`
- Destination: `/backups/weekly-nextcloud`
- Schedule: Weekly Sunday 06:00
- Retention: Keep 4 weekly versions
- Encryption: AES-256

### Encryption passphrase

Choose a strong passphrase for backup encryption. Store it in Vaultwarden. Without this passphrase, backups cannot be restored.

## Verification

```bash
# Container health
docker ps --filter name=duplicati

# Network membership
docker network inspect proxy | grep duplicati

# DNS resolution (from tailnet client)
dig +short backup.${DOMAIN_ROOT} @${TAILSCALE_IP}

# Proxy routing
curl -vk --resolve backup.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://backup.${DOMAIN_ROOT}/

# Backup destination accessible
docker exec duplicati ls /backups
docker exec duplicati ls /source
```

## Updates

Watchtower will auto-update this container. For manual updates:

```bash
docker compose pull && docker compose up -d
```

## Restore Process

1. Open Duplicati UI at `backup.${DOMAIN_ROOT}`
2. Select the backup job to restore from
3. Browse files and select what to restore
4. Choose restore location (original path or alternate)
5. Duplicati decrypts and reassembles the files

For disaster recovery (Duplicati itself lost):
1. Redeploy the Duplicati container
2. Point it at `/backups` destination
3. Use "Restore from configuration" to reimport job definitions
4. Or manually browse the backup files in the UI

## Backup Priorities

| Priority | Data | Why |
| --- | --- | --- |
| Critical | Vaultwarden | All passwords - unrecoverable without backup |
| Critical | Pi-hole config | DNS authority - services unreachable without it |
| Critical | NPM certs and config | TLS and routing - breaks all hostname access |
| High | Actual Budget | Financial history |
| High | Uptime Kuma | Monitor configurations and history |
| Medium | Immich | Photos (large, may take time) |
| Medium | Nextcloud | Cloud files |
| Medium | Arr configs | Service settings (media itself is re-downloadable) |
| Low | OpenClaw | Can be reconfigured from scratch |

## Related Docs

- [NETWORKING.md](../NETWORKING.md)
- [VARIABLES.md](../VARIABLES.md)
- [OPERATIONS.md](../OPERATIONS.md)
- [nginx-proxy-manager.md](nginx-proxy-manager.md)
