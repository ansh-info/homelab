# Jellyfin and Arr Stack

This guide documents the main media stack in the homelab. It covers the containers in the shared media ecosystem, how they depend on common storage and networking, which services are intended to be proxied through Nginx Proxy Manager, and how to verify the stack locally and remotely.

For the shared placeholder vocabulary used in this file, see [../VARIABLES.md](../VARIABLES.md).

Reference compose file:

- [docker-compose/jellyfin-arr-stack/docker-compose.yml](../../docker-compose/jellyfin-arr-stack/docker-compose.yml)

## Purpose

This stack groups the media-management and media-serving services that share downloads, metadata, and media library paths.

The current compose file includes:

- `jellyfin`
- `seerr`
- `radarr`
- `sonarr`
- `prowlarr`
- `bazarr`
- `qbittorrent`
- `homarr`

Currently commented out in the checked-in compose file:

- `lidarr`
- `plex`
- `readarr`

These services do not all play the same role:

- `jellyfin` and `plex` serve media
- `seerr` is the request UI
- `radarr`, `sonarr`, `bazarr`, and `prowlarr` coordinate discovery and metadata
- `qbittorrent` handles downloads
- `homarr` is a dashboard layer

## Dependencies

This stack depends on:

- Docker and Portainer
- the shared Docker network `${PROXY_NETWORK}`
- Pi-hole DNS working for internal service names
- Nginx Proxy Manager being available for hostname-based ingress
- stable persistent storage for configs, downloads, and media
- GPU support for `jellyfin` if hardware acceleration is expected

The stack can start without NPM, but hostname-based access to services like `seerr.${DOMAIN_ROOT}` depends on DNS and NPM both being correct.

## Placeholder Variables

- `${HOSTNAME}`: Linux hostname of the homelab server
- `${TAILSCALE_IP}`: homelab Tailscale IP
- `${DOMAIN_ROOT}`: internal DNS suffix
- `${PROXY_NETWORK}`: shared Docker network
- `${MEDIA_ROOT}`: base path for media services
- `${DOWNLOADS_ROOT}`: base path for downloads
- `${CONFIG_ROOT}`: base path for service configuration directories

## Current Example Values

```text
${HOSTNAME}=homelab
${TAILSCALE_IP}=100.123.147.108
${DOMAIN_ROOT}=homelab.ansh-info.com
${PROXY_NETWORK}=proxy
${MEDIA_ROOT}=/mnt/ssd/docker-volumes/arr
${DOWNLOADS_ROOT}=/mnt/ssd/docker-volumes/arr/qbittorrent/downloads
${CONFIG_ROOT}=/mnt/ssd/docker-volumes/arr
```

## Service Inventory

Current important service details from the compose file:

- `seerr`
  - internal port `5055`
  - attached to `${PROXY_NETWORK}`
  - intended to be reverse-proxied
- `radarr`
  - internal port `7878`
  - attached to `${PROXY_NETWORK}`
  - intended to be reverse-proxied
- `sonarr`
  - internal port `8989`
  - attached to `${PROXY_NETWORK}`
  - intended to be reverse-proxied
- `prowlarr`
  - internal port `9696`
  - attached to `${PROXY_NETWORK}`
  - intended to be reverse-proxied
- `bazarr`
  - internal port `6767`
  - attached to `${PROXY_NETWORK}`
  - intended to be reverse-proxied
- `jellyfin`
  - internal app port `8096`
  - host port `8920` exposed
  - attached to `${PROXY_NETWORK}`
  - can be reverse-proxied, but also exposes some host ports for specific use cases
- `qbittorrent`
  - internal web UI port `8080`
  - torrent port `6881` exposed on host
  - attached to `${PROXY_NETWORK}`
- `homarr`
  - currently present but not attached to `${PROXY_NETWORK}` in the compose file
- `lidarr`
  - currently commented out in the checked-in compose file
- `plex`
  - currently commented out in the checked-in compose file

## Storage Model

This stack relies heavily on shared host paths. Path consistency matters because several services must agree on where media and downloads live.

Examples from the current compose file:

- `${CONFIG_ROOT}/radarr/config`
- `${CONFIG_ROOT}/sonarr/config`
- `${CONFIG_ROOT}/prowlarr/config`
- `${CONFIG_ROOT}/bazarr/config`
- `${CONFIG_ROOT}/jellyfin/config`
- `${CONFIG_ROOT}/seerr/config`
- `${CONFIG_ROOT}/qbittorrent/config`
- `${CONFIG_ROOT}/qbittorrent/downloads`
- `${CONFIG_ROOT}/radarr/movies`
- `${CONFIG_ROOT}/sonarr/tvseries`
- `${CONFIG_ROOT}/homarr/config`
- `${CONFIG_ROOT}/homarr/icons`
- `${CONFIG_ROOT}/homarr/data`

Current migrated host layout:

- `/mnt/ssd/docker-volumes/arr/radarr/config`
- `/mnt/ssd/docker-volumes/arr/radarr/movies`
- `/mnt/ssd/docker-volumes/arr/sonarr/config`
- `/mnt/ssd/docker-volumes/arr/sonarr/tvseries`
- `/mnt/ssd/docker-volumes/arr/prowlarr/config`
- `/mnt/ssd/docker-volumes/arr/bazarr/config`
- `/mnt/ssd/docker-volumes/arr/qbittorrent/config`
- `/mnt/ssd/docker-volumes/arr/qbittorrent/downloads`
- `/mnt/ssd/docker-volumes/arr/jellyfin/config`
- `/mnt/ssd/docker-volumes/arr/seerr/config`
- `/mnt/ssd/docker-volumes/arr/homarr/config`
- `/mnt/ssd/docker-volumes/arr/homarr/icons`
- `/mnt/ssd/docker-volumes/arr/homarr/data`

Why path consistency matters:

- `qbittorrent` downloads content into shared download paths
- `radarr` and `sonarr` must see those same paths to import media
- `jellyfin` must see the final media library paths
- if one container sees a different host path than another, imports and library sync will fail

### Important Path Rule

For this migration, the host paths changed, but the container-internal paths stayed the same.

Example:

- host path:
  - `/mnt/ssd/docker-volumes/arr/radarr/movies`
- container path:
  - `/data/movies`

That means many application settings do not need to change if they already point at the container-internal paths.

Examples:

- Radarr should still use `/data/movies` and `/downloads`
- Sonarr should still use `/data/tvshows` and `/downloads`
- qBittorrent should still use `/downloads`
- Jellyfin should still use `/data/tvshows` and `/data/movies`

What changed:

- the host-side source of the bind mount

What did not change:

- the in-container destination path for most active services

So after migration:

- verify app paths
- do not blindly rewrite app configs if the in-container paths are unchanged

## Networking Model

Most services in this stack are designed to stay internal and be reached through NPM over `${PROXY_NETWORK}`.

That means:

- their normal app ports are not published to the host
- NPM should reach them by container name
- Pi-hole should resolve their hostnames to `${TAILSCALE_IP}`

Expected reverse-proxy targets include:

- `seerr.${DOMAIN_ROOT}` -> `seerr:5055`
- `radarr.${DOMAIN_ROOT}` -> `radarr:7878`
- `sonarr.${DOMAIN_ROOT}` -> `sonarr:8989`
- `prowlarr.${DOMAIN_ROOT}` -> `prowlarr:9696`
- `bazarr.${DOMAIN_ROOT}` -> `bazarr:6767`
- `jellyfin.${DOMAIN_ROOT}` -> `jellyfin:8096`

Current exceptions in the compose file:

- `qbittorrent` publishes `6881/tcp` and `6881/udp`
- `jellyfin` publishes `8920`, `7359/udp`, and `1900/udp`
- `homarr` is present but has no host ports and is not attached to `${PROXY_NETWORK}`
- `lidarr` and `plex` are currently commented out

These direct exposures are stack-specific exceptions, not the primary ingress pattern.

## GPU and Runtime Notes

The current compose file sets:

```yaml
runtime: nvidia
```

for `jellyfin`.

This means the host needs a working NVIDIA runtime if hardware acceleration is expected.

Current Jellyfin GPU settings in the compose file are:

```yaml
runtime: nvidia
environment:
  - NVIDIA_VISIBLE_DEVICES=all
  - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
```

This is a valid setup if the Docker host still supports the NVIDIA runtime path and the runtime is installed correctly.

If the host lacks compatible GPU support:

- `jellyfin` may fail to start
- hardware-accelerated transcoding may not work

Verify on the host:

```bash
docker info | grep -i runtime
```

## Portainer Deployment

Deploy this stack through Portainer using:

- [docker-compose/jellyfin-arr-stack/docker-compose.yml](../../docker-compose/jellyfin-arr-stack/docker-compose.yml)

Before deployment:

1. ensure `${PROXY_NETWORK}` exists
2. ensure all host directories in the compose file exist
3. ensure download and media paths are mounted where expected
4. ensure any required GPU runtime is available
5. ensure Pi-hole and NPM are already healthy if you want immediate hostname-based access

After deployment:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

After a storage migration, also verify:

- Radarr still sees `/data/movies`
- Sonarr still sees `/data/tvshows`
- qBittorrent still downloads into `/downloads`
- Jellyfin libraries still point at the same in-container media paths

## Remote Host Verification

Run these commands on `${HOSTNAME}`.

### Confirm the main containers are running

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Look especially for:

- `seerr`
- `radarr`
- `sonarr`
- `prowlarr`
- `bazarr`
- `jellyfin`
- `qbittorrent`
- `homarr`

### Confirm network membership

```bash
docker network inspect ${PROXY_NETWORK}
```

For normal NPM access, services like `seerr`, `radarr`, `sonarr`, `prowlarr`, `bazarr`, `jellyfin`, and `qbittorrent` should appear on `${PROXY_NETWORK}`.

Do not assume `homarr` will appear there unless the compose file is changed. `lidarr` and `plex` are currently commented out.

### Confirm Seerr health

```bash
docker logs --tail 100 seerr
docker inspect --format='{{json .State.Health}}' seerr
```

### Confirm a backend can answer inside Docker

Examples:

```bash
docker exec nginx-proxy-manager sh -lc 'wget -qO- http://seerr:5055/ | head'
docker exec nginx-proxy-manager sh -lc 'wget -qO- http://radarr:7878/ | head'
```

These are useful when DNS is fine but proxy routing still seems broken.

### Confirm media paths exist on the host

```bash
ls -ld ${CONFIG_ROOT} ${DOWNLOADS_ROOT}
```

## Local Tailscale Client Verification

Run these commands from a client connected to the tailnet.

### Confirm DNS resolution

```bash
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
dig +short jellyfin.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

Expected:

```text
${TAILSCALE_IP}
```

### Confirm NPM routing to Seerr

```bash
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
```

Expected from the current working setup:

- TLS succeeds
- upstream returns a redirect such as `HTTP/2 307`
- response may include `location: /login`

### Confirm NPM routing to Jellyfin

```bash
curl -vk --resolve jellyfin.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://jellyfin.${DOMAIN_ROOT}/
```

## Suggested NPM Proxy Targets

Typical targets for this stack:

- `seerr.${DOMAIN_ROOT}` -> `seerr:5055`
- `radarr.${DOMAIN_ROOT}` -> `radarr:7878`
- `sonarr.${DOMAIN_ROOT}` -> `sonarr:8989`
- `prowlarr.${DOMAIN_ROOT}` -> `prowlarr:9696`
- `bazarr.${DOMAIN_ROOT}` -> `bazarr:6767`
- `jellyfin.${DOMAIN_ROOT}` -> `jellyfin:8096`

### How To Fill NPM For These Services

For the active services in this stack, the practical NPM pattern is:

| Public hostname | Scheme | Forward Hostname / IP | Forward Port |
| --- | --- | --- | --- |
| `seerr.${DOMAIN_ROOT}` | `http` | `seerr` | `5055` |
| `radarr.${DOMAIN_ROOT}` | `http` | `radarr` | `7878` |
| `sonarr.${DOMAIN_ROOT}` | `http` | `sonarr` | `8989` |
| `prowlarr.${DOMAIN_ROOT}` | `http` | `prowlarr` | `9696` |
| `bazarr.${DOMAIN_ROOT}` | `http` | `bazarr` | `6767` |
| `jellyfin.${DOMAIN_ROOT}` | `http` | `jellyfin` | `8096` |

Recommended NPM toggles for these entries:

- `Access List`: `Publicly Accessible`
- `Cache Assets`: enabled
- `Block Common Exploits`: enabled
- `Websockets Support`: enabled
- SSL certificate: `*.${DOMAIN_ROOT}`
- `Force SSL`: enabled
- `HTTP/2 Support`: enabled
- `HSTS Enabled`: enabled
- `HSTS Sub-domains`: enabled

Optional entries only if those services are enabled and attached to `${PROXY_NETWORK}`:

| Public hostname | Scheme | Forward Hostname / IP | Forward Port |
| --- | --- | --- | --- |
| `lidarr.${DOMAIN_ROOT}` | `http` | `lidarr` | `8686` |
| `homarr.${DOMAIN_ROOT}` | `http` | `homarr` | `7575` |
| `plex.${DOMAIN_ROOT}` | `http` | `plex` | `32400` |

Before adding an NPM entry for a service, confirm that:

- the container is attached to `${PROXY_NETWORK}`
- the service is listening on the expected internal port
- the service should actually be reverse-proxied rather than accessed through a special host port

## Common Failure Modes

### DNS works, but only some services load through NPM

Likely causes:

- the service is not attached to `${PROXY_NETWORK}`
- the NPM upstream host or port is wrong
- the service is healthy enough to appear `Up` but the app is not responding correctly

Checks:

```bash
docker network inspect ${PROXY_NETWORK}
docker logs --tail 100 <service-name>
```

### Downloads complete, but imports fail in Radarr or Sonarr

Likely causes:

- `qbittorrent` and the Arr services do not see the same download path
- host paths are mounted inconsistently between services

Checks:

- compare volume mappings in the compose file
- inspect the download path inside both containers
- verify the apps still reference container paths like `/downloads`, not some unexpected host path

### Jellyfin container starts, but transcoding fails

Likely causes:

- NVIDIA runtime not configured correctly
- container does not have the expected GPU access

Checks:

```bash
docker logs --tail 100 jellyfin
docker info | grep -i runtime
```

### A service is running, but NPM cannot proxy to it

Likely causes:

- container not attached to `${PROXY_NETWORK}`
- wrong internal port configured in NPM
- service listens on a different port than expected

### Some services in the compose file are not proxy-ready

Current examples from the compose file:

- `homarr` is present but does not currently join `${PROXY_NETWORK}`
- `lidarr` is currently commented out
- `plex` is currently commented out

That means:

- they may work locally through direct host access
- but they are not immediately ready for the same NPM pattern as `seerr` or `radarr`

## Recovery Procedure

Use this order when a media-stack service stops working:

1. Confirm the container is running.
2. Confirm the container is healthy if it has a health check.
3. Confirm the service is attached to `${PROXY_NETWORK}` if it should be proxied.
4. Confirm Pi-hole resolves the hostname to `${TAILSCALE_IP}`.
5. Confirm NPM has the correct upstream host and port.
6. Confirm shared media and download paths are visible where the service expects them.
7. Check container logs for service-specific failures.

## Notes

- This stack is operationally important because several services share storage assumptions.
- NPM routing issues and media-path issues can look similar from the browser, but they are different failure classes.
- The compose file currently mixes internal reverse-proxied services with a few host-port exceptions. Document those exceptions instead of assuming the whole stack follows one ingress pattern.

## Related Docs

- [docs/NETWORKING.md](../NETWORKING.md)
- [docs/stacks/nginx-proxy-manager.md](nginx-proxy-manager.md)
- [docs/stacks/pihole.md](pihole.md)
