# Variables and Example Values

This file centralizes the placeholder variables used across the homelab documentation. Use these placeholders when writing or updating docs so host-specific values stay consistent.

The placeholders are documentation variables only. They are not automatically exported shell variables unless you define them yourself in your environment.

## Core Host and Network Variables

| Variable | Meaning | Current Example |
| --- | --- | --- |
| `${HOSTNAME}` | Linux hostname of the homelab server | `homelab` |
| `${TAILSCALE_IP}` | Tailscale IPv4 address of the homelab host | `100.123.147.108` |
| `${DOMAIN_ROOT}` | Internal private service suffix used with Pi-hole and NPM | `homelab.ansh-info.com` |
| `${PROXY_NETWORK}` | Shared external Docker network for reverse-proxied services | `proxy` |
| `${TZ}` | Host timezone used in container environments | `Asia/Kolkata` |

## Host Storage Variables

| Variable | Meaning | Current Example |
| --- | --- | --- |
| `${DATA_ROOT}` | Base path for persistent service data | `/mnt/ssd` |
| `${MEDIA_ROOT}` | Base path for media services and libraries | `/mnt/ssd/docker-volumes/arr` |
| `${STACK_ROOT}` | Base path for stack-specific persistent directories | `/mnt/ssd/docker-compose` |
| `${CONFIG_ROOT}` | Base path for media-stack config directories | `/mnt/ssd/docker-volumes/arr` |
| `${DOWNLOADS_ROOT}` | Base path for downloads used by the media stack | `/mnt/ssd/docker-volumes/arr/qbittorrent/downloads` |

## Pi-hole Variables

| Variable | Meaning | Current Example |
| --- | --- | --- |
| `${PIHOLE_ETC_ROOT}` | Host path mounted to `/etc/pihole` | `/mnt/ssd/docker-volumes/pihole/etc-pihole` |
| `${PIHOLE_DNSMASQ_ROOT}` | Host path mounted to `/etc/dnsmasq.d` | `/mnt/ssd/docker-volumes/pihole/etc-dnsmasq.d` |

## Nginx Proxy Manager Variables

| Variable | Meaning | Current Example |
| --- | --- | --- |
| `${NPM_DATA_ROOT}` | Host path for NPM application data | `/mnt/ssd/docker-volumes/nginx-proxy-manager/data` |
| `${NPM_CERT_ROOT}` | Host path for NPM certificate storage | `/mnt/ssd/docker-volumes/nginx-proxy-manager/letsencrypt` |

## Immich Variables

| Variable | Meaning | Current Example |
| --- | --- | --- |
| `${IMMICH_ENV_FILE}` | Path to the Immich env file | `docker-compose/immich/stack.env` |
| `${IMMICH_UPLOAD_ROOT}` | Host path for Immich uploads | `/mnt/ssd/docker-volumes/immich/library` |
| `${IMMICH_DB_ROOT}` | Host path for Immich PostgreSQL data | `/mnt/ssd/docker-volumes/immich/postgres` |
| `${IMMICH_MODEL_CACHE_ROOT}` | Host path for Immich model cache | `/mnt/ssd/docker-volumes/immich/model-cache` |

## Nextcloud Variables

| Variable | Meaning | Current Example |
| --- | --- | --- |
| `${NEXTCLOUD_DATA_ROOT}` | Host path for Nextcloud data | `/mnt/ssd/docker-volumes/nextcloud/data` |

## Watchtower Variables

| Variable | Meaning | Current Example |
| --- | --- | --- |
| `${WATCHTOWER_INTERVAL_SECONDS}` | Watchtower polling interval | `86400` |

## Notes

- When multiple docs mention the same variable, prefer using the definitions in this file rather than inventing a new variant.
- If a new stack introduces a new placeholder, add it here first.
- Stack-specific env-file keys such as `UPLOAD_LOCATION` or `DB_PASSWORD` should still be documented in the relevant stack guide.

## Related Docs

- [README.md](../README.md)
- [docs/README.md](README.md)
- [SETUP.md](SETUP.md)
- [NETWORKING.md](NETWORKING.md)
