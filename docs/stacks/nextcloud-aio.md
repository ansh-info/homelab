# Nextcloud AIO Stack

This guide documents the Nextcloud All-in-One deployment in the homelab, including the current reverse-proxy-oriented configuration, storage considerations, and verification steps.

For the shared placeholder vocabulary used in this file, see [../VARIABLES.md](../VARIABLES.md).

Reference compose file:

- [docker-compose/nextcloud-aio/docker-compose.yml](../../docker-compose/nextcloud-aio/docker-compose.yml)

## Purpose

Nextcloud AIO provides the self-hosted cloud application stack. In this homelab, the checked-in configuration is oriented toward running Nextcloud behind a reverse proxy rather than exposing its default ports directly on the host.

## Dependencies

Nextcloud AIO depends on:

- Docker and Portainer
- access to the Docker socket
- persistent Docker volume `nextcloud_aio_mastercontainer`
- the shared Docker network `${PROXY_NETWORK}`
- Pi-hole and NPM if you want hostname-based access through the private domain

The compose file also assumes:

- the host can support the configured upload limits
- the host can support NVIDIA-related options if they remain enabled

## Placeholder Variables

- `${HOSTNAME}`: Linux hostname of the homelab server
- `${TAILSCALE_IP}`: homelab Tailscale IP
- `${DOMAIN_ROOT}`: internal DNS suffix
- `${PROXY_NETWORK}`: shared Docker network
- `${NEXTCLOUD_DATA_ROOT}`: host path for Nextcloud data

## Current Example Values

```text
${HOSTNAME}=homelab
${TAILSCALE_IP}=100.123.147.108
${DOMAIN_ROOT}=homelab.ansh-info.com
${PROXY_NETWORK}=proxy
${NEXTCLOUD_DATA_ROOT}=/mnt/ssd/docker-volumes/nextcloud/data
```

## Compose Highlights

Current important details from the stack:

- service: `nextcloud-aio-mastercontainer`
- attached to `${PROXY_NETWORK}`
- mounts:
  - Docker socket read-only
  - named volume `nextcloud_aio_mastercontainer`
- current reverse-proxy-oriented env values include:
  - `APACHE_PORT=11000`
  - `APACHE_IP_BINDING=127.0.0.1`
  - `APACHE_ADDITIONAL_NETWORK=proxy`
  - `SKIP_DOMAIN_VALIDATION=true`
  - `NEXTCLOUD_DATADIR=/mnt/ssd/docker-volumes/nextcloud/data`
  - `NEXTCLOUD_ENABLE_NVIDIA_GPU=true`

Important notes:

- the checked-in compose file does not publish `80`, `8080`, or `8443`
- this setup assumes Nextcloud traffic will be handled through a reverse-proxy path
- some environment settings should be revisited carefully before changing an existing deployment

## Portainer Deployment

Deploy through Portainer using:

- [docker-compose/nextcloud-aio/docker-compose.yml](../../docker-compose/nextcloud-aio/docker-compose.yml)

Before deployment:

1. ensure `${PROXY_NETWORK}` exists
2. ensure `${NEXTCLOUD_DATA_ROOT}` exists if used
3. ensure the Docker socket mount is acceptable for the host
4. ensure reverse-proxy assumptions are understood before first install

After deployment:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker volume ls | grep nextcloud_aio_mastercontainer
```

## Reverse Proxy Notes

The checked-in config is already shaped for reverse proxy use:

- Apache is configured to bind to `127.0.0.1`
- an additional Docker network `${PROXY_NETWORK}` is declared for proxy interoperability

Because Nextcloud AIO has its own operational model, verify the exact reverse-proxy procedure carefully before changing the running setup.

Documented assumption for this homelab:

- if Nextcloud is exposed through a private hostname, it should align with the same Pi-hole -> NPM -> backend pattern as the rest of the private services

## Host Data Directory Preparation

Before a fresh install, prepare the host data directory:

```bash
sudo mkdir -p /mnt/ssd/docker-volumes/nextcloud/data
sudo chown -R 33:33 /mnt/ssd/docker-volumes/nextcloud/data
```

This matches the current working homelab setup.

## Domain Model

This homelab uses two separate hostnames for Nextcloud AIO:

- admin UI:
  - `nextcloud-admin.${DOMAIN_ROOT}` -> `nextcloud-aio-mastercontainer:8080`
- actual Nextcloud app:
  - `nextcloud.${DOMAIN_ROOT}` -> `nextcloud-aio-apache:11000`

Important:

- the admin hostname is only for the AIO management UI
- the app hostname is the real Nextcloud domain that users should access
- do not point the main app hostname to `nextcloud-aio-mastercontainer:8080`

## NPM Proxy Entries

Use two separate proxy hosts in NPM.

### Admin UI

Use this for the AIO management and setup interface:

| Public hostname | Scheme | Forward Hostname / IP | Forward Port |
| --- | --- | --- | --- |
| `nextcloud-admin.${DOMAIN_ROOT}` | `https` or `http` | `nextcloud-aio-mastercontainer` | `8080` |

### Actual Nextcloud App

Use this for the user-facing Nextcloud instance:

| Public hostname | Scheme | Forward Hostname / IP | Forward Port |
| --- | --- | --- | --- |
| `nextcloud.${DOMAIN_ROOT}` | `http` | `nextcloud-aio-apache` | `11000` |

Recommended NPM toggles for both entries:

- `Access List`: `Publicly Accessible`
- `Cache Assets`: enabled
- `Block Common Exploits`: enabled
- `Websockets Support`: enabled
- SSL certificate: `*.${DOMAIN_ROOT}`
- `Force SSL`: enabled
- `HTTP/2 Support`: enabled
- `HSTS Enabled`: enabled
- `HSTS Sub-domains`: enabled

Important:

- the admin host and app host should not share the same upstream target
- the app host should not point to `nextcloud-aio-mastercontainer:8080`
- the value entered in the AIO setup UI is the final app domain, not the admin domain

## What To Enter In The AIO Setup UI

When AIO asks for:

> Please type in the domain that will be used for Nextcloud

enter only the final app hostname:

```text
nextcloud.${DOMAIN_ROOT}
```

With current example values:

```text
nextcloud.homelab.ansh-info.com
```

Do not enter:

- `https://nextcloud.${DOMAIN_ROOT}`
- `nextcloud-admin.${DOMAIN_ROOT}`
- `nextcloud-aio-mastercontainer`
- `${TAILSCALE_IP}`

The field expects the final hostname only.

## Remote Host Verification

Run these commands on `${HOSTNAME}`.

```bash
docker ps --filter name=nextcloud-aio-mastercontainer
docker logs --tail 100 nextcloud-aio-mastercontainer
docker volume ls | grep nextcloud_aio_mastercontainer
docker network inspect ${PROXY_NETWORK}
```

## Local Tailscale Client Verification

If a private hostname is configured for Nextcloud, verify:

```bash
dig +short nextcloud.${DOMAIN_ROOT} @${TAILSCALE_IP}
curl -vk --resolve nextcloud.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://nextcloud.${DOMAIN_ROOT}/
```

Only use this if an NPM proxy host and Pi-hole DNS entry for Nextcloud have actually been created.

For the admin UI:

```bash
dig +short nextcloud-admin.${DOMAIN_ROOT} @${TAILSCALE_IP}
curl -vk --resolve nextcloud-admin.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://nextcloud-admin.${DOMAIN_ROOT}/containers
```

## Common Failure Modes

### Mastercontainer starts, but app access is unclear

Likely causes:

- Nextcloud AIO still needs its own internal setup completed
- reverse-proxy configuration is incomplete
- the private hostname has not been fully wired through Pi-hole and NPM

### Startup issues after changing storage or GPU settings

Likely causes:

- invalid data path changes after initial deployment
- host missing required GPU support
- Docker socket or permissions issues

### Nextcloud container shows PostgreSQL password authentication failures

Likely cause:

- stale AIO PostgreSQL state from a previous failed or partial install

Typical log pattern:

```text
password authentication failed for user "oc_nextcloud"
```

This usually means:

- the database volume already contains older credentials
- the current AIO instance generated different credentials
- the install is no longer a clean first boot

For a fresh install with no data to preserve, the fix is to reset the AIO containers and volumes, then start again cleanly.

## Recovery Procedure

Use this order:

1. Confirm the mastercontainer is running.
2. Confirm the named Docker volume exists.
3. Confirm `${PROXY_NETWORK}` attachment if reverse proxying is expected.
4. Review logs before changing storage-related settings.
5. Verify Pi-hole and NPM only after the mastercontainer itself is healthy.

If the install is supposed to be fresh and you hit database password failures:

1. stop and remove all `nextcloud-aio-*` containers
2. remove the AIO Docker volumes if no data needs to be kept
3. reset the host data directory if needed
4. redeploy the stack
5. enter `nextcloud.${DOMAIN_ROOT}` in the AIO UI again

## Related Docs

- [docs/NETWORKING.md](../NETWORKING.md)
- [docs/stacks/nginx-proxy-manager.md](nginx-proxy-manager.md)
- [docs/stacks/pihole.md](pihole.md)
