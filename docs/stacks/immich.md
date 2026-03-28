# Immich Stack

This guide documents the Immich deployment in the homelab, including its service layout, environment file expectations, storage requirements, reverse-proxy path, and verification steps.

For the shared placeholder vocabulary used in this file, see [../VARIABLES.md](../VARIABLES.md).

Reference files:

- [docker-compose/immich/docker-compose.yml](../../docker-compose/immich/docker-compose.yml)
- [docker-compose/immich/stack.env](../../docker-compose/immich/stack.env)

## Purpose

Immich provides the self-hosted photo and media management system in the homelab.

The current stack includes:

- `immich_server`
- `immich_machine_learning`
- `immich_redis`
- `immich_postgres`

These containers work together as one application:

- `immich_server` is the main web and API service
- `immich_machine_learning` handles model-backed tasks
- `immich_redis` provides caching and queue support
- `immich_postgres` provides database storage

## Dependencies

Immich depends on:

- Docker and Portainer
- the shared Docker network `${PROXY_NETWORK}`
- a valid `stack.env` file
- persistent storage for uploads, model cache, and database data
- Pi-hole and NPM if you want hostname-based private access

Immich should be deployed after Pi-hole and NPM if you want immediate access through `immich.${DOMAIN_ROOT}`.

## Placeholder Variables

- `${HOSTNAME}`: Linux hostname of the homelab server
- `${TAILSCALE_IP}`: homelab Tailscale IP
- `${DOMAIN_ROOT}`: internal DNS suffix
- `${PROXY_NETWORK}`: shared Docker network
- `${IMMICH_ENV_FILE}`: path to the Immich environment file
- `${IMMICH_UPLOAD_ROOT}`: path for uploaded media
- `${IMMICH_DB_ROOT}`: path for PostgreSQL data
- `${IMMICH_MODEL_CACHE_ROOT}`: path for machine-learning model cache

## Current Example Values

```text
${HOSTNAME}=homelab
${TAILSCALE_IP}=100.123.147.108
${DOMAIN_ROOT}=homelab.ansh-info.com
${PROXY_NETWORK}=proxy
${IMMICH_ENV_FILE}=docker-compose/immich/stack.env
${IMMICH_UPLOAD_ROOT}=/mnt/ssd/docker-volumes/immich/library
${IMMICH_DB_ROOT}=/mnt/ssd/docker-volumes/immich/postgres
${IMMICH_MODEL_CACHE_ROOT}=/mnt/ssd/docker-volumes/immich/model-cache
```

## Compose Highlights

Current important details from the stack:

- `immich_server`
  - container name: `immich_server`
  - internal app port: `2283`
  - attached to `${PROXY_NETWORK}`
  - depends on Redis and PostgreSQL
- `immich_machine_learning`
  - attached to `${PROXY_NETWORK}`
  - uses a persistent model cache on the host
- `immich_redis`
  - attached to `${PROXY_NETWORK}`
- `immich_postgres`
  - attached to `${PROXY_NETWORK}`
  - stores its data in `${DB_DATA_LOCATION}`

Important note:

- the stack uses `env_file: stack.env`
- the checked-in compose file intentionally references placeholders instead of hard-coded secret values

## Environment File

The Immich stack depends on a populated `stack.env` file. That file should define at least the values referenced in the compose file.

At minimum, verify:

- `UPLOAD_LOCATION`
- `DB_DATA_LOCATION`
- `DB_PASSWORD`
- `DB_USERNAME`
- `DB_DATABASE_NAME`
- `IMMICH_VERSION` if you are pinning a non-default release

Before deployment:

```bash
sed -n '1,200p' ${IMMICH_ENV_FILE}
```

Do not commit secrets casually. The env file should be treated as operational configuration, not public documentation content.

## Storage Model

Immich uses three important storage layers:

- upload storage for media files
- PostgreSQL storage for application data
- model cache storage for machine-learning assets

Examples from the current compose file:

- `/mnt/ssd/docker-volumes/immich/library:/data`
- `/mnt/ssd/docker-volumes/immich/postgres:/var/lib/postgresql/data`
- `/mnt/ssd/docker-volumes/immich/model-cache:/cache`

Before deployment, create and verify the host paths:

```bash
mkdir -p ${IMMICH_MODEL_CACHE_ROOT}
```

The upload and database locations come from `stack.env`, so verify those values before creating paths.

## Portainer Deployment

Deploy Immich through Portainer using:

- [docker-compose/immich/docker-compose.yml](../../docker-compose/immich/docker-compose.yml)

Before deployment:

1. ensure `${PROXY_NETWORK}` exists
2. ensure `stack.env` exists and contains the required values
3. ensure upload, database, and model-cache paths exist
4. ensure Pi-hole and NPM are already healthy if you want hostname-based access

After deployment:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Look for:

- `immich_server`
- `immich_machine_learning`
- `immich_redis`
- `immich_postgres`

## Suggested NPM Proxy Target

For private hostname access, the normal target is:

- `immich.${DOMAIN_ROOT}` -> `immich_server:2283`

### How To Fill NPM For Immich

Use this proxy-host entry:

| Public hostname | Scheme | Forward Hostname / IP | Forward Port |
| --- | --- | --- | --- |
| `immich.${DOMAIN_ROOT}` | `http` | `immich_server` | `2283` |

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

Before adding this proxy host:

- confirm Pi-hole resolves `immich.${DOMAIN_ROOT}` to `${TAILSCALE_IP}`
- confirm `immich_server` is attached to `${PROXY_NETWORK}`
- confirm the service is healthy

## Remote Host Verification

Run these commands on `${HOSTNAME}`.

### Confirm container status

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

### Confirm network membership

```bash
docker network inspect ${PROXY_NETWORK}
```

### Confirm Immich server logs

```bash
docker logs --tail 100 immich_server
docker logs --tail 100 immich_machine_learning
docker logs --tail 100 immich_postgres
```

### Confirm the backend answers inside Docker

```bash
docker exec nginx-proxy-manager sh -lc 'wget -qO- http://immich_server:2283/ | head'
```

### Confirm env file values are present where expected

```bash
sed -n '1,200p' docker-compose/immich/stack.env
```

## Local Tailscale Client Verification

Run these commands from a client on the tailnet.

### Confirm DNS resolution

```bash
dig +short immich.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

Expected:

```text
${TAILSCALE_IP}
```

### Confirm NPM routing

```bash
curl -vk --resolve immich.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://immich.${DOMAIN_ROOT}/
```

Expected:

- TLS succeeds
- certificate matches the hostname
- Immich responds with its normal web app output or redirect behavior

## Common Failure Modes

### Containers start, but the web UI does not load

Likely causes:

- `immich_server` unhealthy
- bad NPM upstream target
- DNS missing for `immich.${DOMAIN_ROOT}`

Checks:

```bash
docker logs --tail 100 immich_server
docker network inspect ${PROXY_NETWORK}
dig +short immich.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

### Database issues on startup

Likely causes:

- bad database credentials in `stack.env`
- invalid or missing `${DB_DATA_LOCATION}`
- PostgreSQL volume permission problems

Checks:

```bash
docker logs --tail 100 immich_postgres
```

### Machine-learning features fail

Likely causes:

- model cache path missing
- machine-learning container unhealthy
- hardware-acceleration assumptions not met if later enabled

Checks:

```bash
docker logs --tail 100 immich_machine_learning
```

## Recovery Procedure

Use this order when Immich stops working:

1. Confirm all four containers are running.
2. Confirm `immich_server` is attached to `${PROXY_NETWORK}`.
3. Confirm `stack.env` values are correct.
4. Confirm Pi-hole resolves `immich.${DOMAIN_ROOT}` to `${TAILSCALE_IP}`.
5. Confirm NPM points `immich.${DOMAIN_ROOT}` to `immich_server:2283`.
6. Check `immich_server`, `immich_machine_learning`, and `immich_postgres` logs.

## Related Docs

- [docs/NETWORKING.md](../NETWORKING.md)
- [docs/stacks/nginx-proxy-manager.md](nginx-proxy-manager.md)
- [docs/stacks/pihole.md](pihole.md)
