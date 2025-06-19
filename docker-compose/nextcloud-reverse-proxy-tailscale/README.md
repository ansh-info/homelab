## Self-Hosted Nextcloud with Caddy Reverse Proxy

This setup provides a **local self-hosted Nextcloud server** using Docker Compose, MariaDB, Redis, and Caddy as a reverse proxy over **Tailscale HTTPS**.

### Stack Overview

| Service     | Purpose                                    |
| ----------- | ------------------------------------------ |
| `nextcloud` | Core Nextcloud application (Apache)        |
| `mariadb`   | MariaDB database backend                   |
| `redis`     | Redis caching backend                      |
| `cron`      | Background job runner                      |
| `caddy`     | Reverse proxy + internal TLS via Tailscale |

## Directory Structure

```bash
/mnt/ssd/nextcloud/
├── html/           # Nextcloud app data
├── db/             # MariaDB data
├── caddy_data/     # Caddy TLS & state
├── caddy_config/   # Caddy runtime config
├── Caddyfile       # Caddy reverse proxy rules
```

## `.env` Environment Variables

Here are the key environment variables used (visible from your UI screenshot):

| Variable                         | Description                     |
| -------------------------------- | ------------------------------- |
| `MYSQL_ROOT_PASSWORD`            | Root password for MariaDB       |
| `MYSQL_DATABASE`                 | Database name for Nextcloud     |
| `MYSQL_USER`                     | Database user for Nextcloud     |
| `MYSQL_PASSWORD`                 | Password for the above user     |
| `MARIADB_AUTO_UPGRADE`           | Enables auto-upgrade (1 = yes)  |
| `MARIADB_DISABLE_UPGRADE_BACKUP` | Skips backup before upgrade     |
| `MYSQL_HOST`                     | Hostname of the MariaDB service |
| `REDIS_HOST`                     | Hostname of the Redis service   |

## Docker Compose Launch

> **Ensure volumes and network paths (`/mnt/ssd/nextcloud/`) exist and are writable.**

```bash
docker compose up -d
```

## Caddy Reverse Proxy (HTTPS via Tailscale)

Your `Caddyfile` routes traffic from your Tailscale domain to the local `app:80` container:

```caddy
your_tailnet.tail__.ts.net {
    reverse_proxy app:80
    tls internal
}
```

This uses **internal TLS** because it’s hosted within your private **Tailscale tailnet**.

## Accessing Nextcloud

Once up:

1. Open in browser:
   `https://your_tailnet.tail__.ts.net`

2. First-time setup screen will appear → input DB credentials from your `.env`.

## Notes

- Run `docker compose logs -f` to debug.
- Persistent data is stored under `/mnt/ssd/nextcloud/`.
- Optional: Configure Nextcloud’s `config.php` with Tailscale domain as a **trusted domain**.
