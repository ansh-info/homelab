# Nginx Proxy Manager Stack

This guide documents how Nginx Proxy Manager is used in the homelab, how it depends on Pi-hole and the shared Docker network, and how to verify that hostname-based routing is working correctly.

For the shared placeholder vocabulary used in this file, see [../VARIABLES.md](../VARIABLES.md).

Reference compose file:

- [docker-compose/nginx-proxy-manager/docker-compose.yml](../../docker-compose/nginx-proxy-manager/docker-compose.yml)

## Purpose

Nginx Proxy Manager is the ingress router for the homelab. It accepts HTTP and HTTPS traffic on the host and forwards requests to internal containers based on hostname.

Pi-hole decides which IP a hostname resolves to.

NPM decides which backend container receives the request after that connection reaches the host.

Examples:

- `seerr.${DOMAIN_ROOT}` -> `seerr:5055`
- `immich.${DOMAIN_ROOT}` -> `immich_server:2283`
- `jellyfin.${DOMAIN_ROOT}` -> `jellyfin:8096`

## Dependencies

NPM depends on:

- Tailscale connectivity to the host
- Pi-hole DNS returning `${TAILSCALE_IP}` for internal hostnames
- host ports `80` and `443` being available
- UFW allowing `80` and `443` on `tailscale0`
- the shared Docker network `${PROXY_NETWORK}` existing
- backend containers joining `${PROXY_NETWORK}`
- proxy host entries existing in the NPM UI

NPM should be deployed after Pi-hole, because without working DNS there is no reliable way to validate hostname-based routing end to end.

## Placeholder Variables

- `${TAILSCALE_IP}`: homelab Tailscale IP
- `${HOSTNAME}`: Linux hostname of the homelab server
- `${DOMAIN_ROOT}`: internal DNS suffix
- `${PROXY_NETWORK}`: shared Docker network
- `${NPM_DATA_ROOT}`: host path for NPM data
- `${NPM_CERT_ROOT}`: host path for NPM certificates

## Current Example Values

```text
${TAILSCALE_IP}=100.123.147.108
${HOSTNAME}=homelab
${DOMAIN_ROOT}=homelab.ansh-info.com
${PROXY_NETWORK}=proxy
${NPM_DATA_ROOT}=/mnt/ssd/docker-volumes/nginx-proxy-manager/data
${NPM_CERT_ROOT}=/mnt/ssd/docker-volumes/nginx-proxy-manager/letsencrypt
```

## Compose Highlights

Current important details from the stack:

- ports exposed:
  - `80:80`
  - `443:443`
- network:
  - external Docker network `${PROXY_NETWORK}`
- persistent volumes:
  - `${NPM_DATA_ROOT}:/data`
  - `${NPM_CERT_ROOT}:/etc/letsencrypt`

Important note:

- admin port `81` is not currently published in the compose file
- the deployment model is focused on the reverse proxy listeners on `80` and `443`

## Port Binding Design

Do not bind NPM directly to `${TAILSCALE_IP}:80` or `${TAILSCALE_IP}:443`.

Avoid patterns like:

```yaml
- "${TAILSCALE_IP}:80:80"
- "${TAILSCALE_IP}:443:443"
```

Why:

- this creates the same Tailscale interface race condition described in [docs/NETWORKING.md](../NETWORKING.md)
- Docker may start before `tailscale0` exists
- NPM can fail to bind after reboot

Use:

```yaml
- "80:80"
- "443:443"
```

Then enforce the private boundary with UFW rules on `tailscale0`.

## Portainer Deployment

Deploy NPM through Portainer using:

- [docker-compose/nginx-proxy-manager/docker-compose.yml](../../docker-compose/nginx-proxy-manager/docker-compose.yml)

Before deployment:

1. ensure `${PROXY_NETWORK}` exists
2. ensure `${NPM_DATA_ROOT}` exists
3. ensure `${NPM_CERT_ROOT}` exists
4. ensure ports `80` and `443` are available
5. ensure Pi-hole is already deployed and healthy

After deployment:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker logs --tail 100 nginx-proxy-manager
```

## Proxy Host Model

NPM routes traffic by matching the hostname in the request to a configured proxy host.

Each proxy host typically needs:

- domain name, for example `seerr.${DOMAIN_ROOT}`
- scheme, usually `http`
- forward hostname, usually the container name on `${PROXY_NETWORK}`
- forward port, the internal container port
- SSL certificate for the hostname

Example mappings in this homelab:

- `seerr.${DOMAIN_ROOT}` -> `seerr:5055`
- `immich.${DOMAIN_ROOT}` -> `immich_server:2283`
- `jellyfin.${DOMAIN_ROOT}` -> `jellyfin:8096`
- `pihole.${DOMAIN_ROOT}` -> `pihole:80`

Important:

- Pi-hole making a name resolve does not create the proxy route
- NPM creating a proxy route does not create DNS
- both layers must exist

## Current Proxy Host Patterns

This section documents the current working proxy-host pattern used in the homelab UI.

Default details tab values:

- scheme: `http`, unless the upstream service itself expects HTTPS
- access list: `Publicly Accessible`
- `Cache Assets`: enabled
- `Block Common Exploits`: enabled
- `Websockets Support`: enabled

Default SSL tab values:

- certificate: `*.${DOMAIN_ROOT}`
- `Force SSL`: enabled
- `HTTP/2 Support`: enabled
- `HSTS Enabled`: enabled
- `HSTS Sub-domains`: enabled

Current examples from the working homelab:

| Public hostname | Upstream host | Upstream port | Scheme | Notes |
| --- | --- | --- | --- | --- |
| `bazarr.${DOMAIN_ROOT}` | `bazarr` | `6767` | `http` | Standard Arr UI |
| `immich.${DOMAIN_ROOT}` | `immich_server` | `2283` | `http` | Immich app |
| `jellyfin.${DOMAIN_ROOT}` | `jellyfin` | `8096` | `http` | Jellyfin app |
| `pihole.${DOMAIN_ROOT}` | `pihole` | `80` | `http` | Pi-hole web UI |
| `portainer.${DOMAIN_ROOT}` | `portainer` | `9443` | `https` | Portainer uses TLS upstream |
| `prowlarr.${DOMAIN_ROOT}` | `prowlarr` | `9696` | `http` | Standard Arr UI |
| `qbittorrent.${DOMAIN_ROOT}` | `qbittorrent` | `8080` | `http` | qBittorrent UI |
| `radarr.${DOMAIN_ROOT}` | `radarr` | `7878` | `http` | Standard Arr UI |
| `seerr.${DOMAIN_ROOT}` | `seerr` | `5055` | `http` | Seerr UI |
| `sonarr.${DOMAIN_ROOT}` | `sonarr` | `8989` | `http` | Standard Arr UI |
| `nextcloud-admin.${DOMAIN_ROOT}` | `nextcloud-aio-mastercontainer` | `8080` | `https` or `http` | Admin/setup UI, depending on your current AIO mode |
| `nextcloud.${DOMAIN_ROOT}` | `nextcloud-aio-apache` | `11000` | `http` | Final Nextcloud app |

Additional live examples that are valid only when those services are enabled and attached to `${PROXY_NETWORK}`:

| Public hostname | Upstream host | Upstream port | Scheme | Notes |
| --- | --- | --- | --- | --- |
| `homarr.${DOMAIN_ROOT}` | `homarr` | `7575` | `http` | Requires `homarr` to be attached to `${PROXY_NETWORK}` |
| `lidarr.${DOMAIN_ROOT}` | `lidarr` | `8686` | `http` | Only if `lidarr` is enabled in compose |
| `plex.${DOMAIN_ROOT}` | `plex` | `32400` | `http` | Only if `plex` is enabled in compose |
| `npm.${DOMAIN_ROOT}` | `nginx-proxy-manager` | `81` | `http` | Optional self-proxy for NPM admin |

## How to Add a Proxy Host

In NPM:

1. Open `Proxy Hosts`
2. Create or edit the host
3. In `Details`:
   - enter the public hostname, for example `bazarr.${DOMAIN_ROOT}`
   - set `Scheme`
   - set `Forward Hostname / IP`
   - set `Forward Port`
   - keep `Publicly Accessible` unless you are intentionally using an NPM access list
   - enable `Cache Assets`, `Block Common Exploits`, and `Websockets Support`
4. In `SSL`:
   - select the wildcard certificate `*.${DOMAIN_ROOT}`
   - enable `Force SSL`
   - enable `HTTP/2 Support`
   - enable `HSTS Enabled`
   - enable `HSTS Sub-domains`
5. Save

Important:

- the public hostname must exactly match the DNS name clients will use
- the upstream host must be resolvable by NPM on `${PROXY_NETWORK}`
- the upstream port must be the container's internal service port, not the host-published port

## Certificate Selection

Proxy hosts in this homelab use the wildcard certificate for `*.${DOMAIN_ROOT}`.

With current example values, that is:

- `*.homelab.ansh-info.com`

Certificate issuance is documented separately in:

- [../CLOUDFLARE.md](../CLOUDFLARE.md)

## TLS and SNI Behavior

HTTPS routing in this setup depends on the hostname being present in the request.

Expected behavior:

- `https://seerr.${DOMAIN_ROOT}` works when DNS and NPM are correct
- `https://${TAILSCALE_IP}` may fail with `unrecognized name` or a similar TLS error

Why:

- the certificate is issued for `*.${DOMAIN_ROOT}` or specific hostnames
- NPM uses SNI to select the certificate and virtual host
- a raw IP request does not provide the expected hostname context

This means:

```bash
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
```

is a valid routing test, while:

```bash
curl -vk https://${TAILSCALE_IP}
```

may fail even when the stack is healthy.

## Remote Host Verification

Run these commands on `${HOSTNAME}`.

### Confirm listeners on `80` and `443`

```bash
sudo ss -lntup | egrep ':(80|443)\b'
```

### Confirm the container is running

```bash
docker ps --filter name=nginx-proxy-manager
```

### Confirm NPM is attached to `${PROXY_NETWORK}`

```bash
docker network inspect ${PROXY_NETWORK}
```

### Confirm the default page is reachable locally

```bash
curl -sv http://127.0.0.1 2>&1 | tail -20
```

Expected when no matching hostname is provided:

- NPM may return the default landing page

That means:

- the listener is alive
- NPM is serving traffic
- but the request did not match a configured hostname

### Confirm direct local HTTPS behavior

```bash
curl -skv https://127.0.0.1 2>&1 | tail -20
```

Expected:

- this may fail with a TLS or SNI-related error
- that is normal if the request does not include a hostname NPM can use

## Local Tailscale Client Verification

Run these commands from a client machine on Tailscale.

### Confirm DNS resolution first

```bash
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

Expected:

```text
${TAILSCALE_IP}
```

### Confirm hostname-based HTTPS routing

```bash
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
curl -vk --resolve immich.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://immich.${DOMAIN_ROOT}/
```

Expected:

- the TLS handshake succeeds
- the certificate matches the hostname
- the upstream app returns its expected response or redirect

From the working homelab, a healthy Seerr response looked like:

- `HTTP/2 307`
- `location: /login`

## UFW Expectations

NPM depends on these rules:

```bash
sudo ufw allow in on tailscale0 to any port 80 proto tcp
sudo ufw allow in on tailscale0 to any port 443 proto tcp
```

Verify:

```bash
sudo ufw status verbose
```

## Common Failure Modes

### DNS resolves, but the browser shows the NPM default page

Likely causes:

- no proxy host exists for that hostname
- the hostname in the request does not exactly match the proxy host entry
- Pi-hole resolved the name correctly, but NPM has no matching route

Checks:

```bash
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
```

### DNS resolves, but NPM cannot reach the backend

Likely causes:

- wrong upstream hostname in the proxy host
- wrong upstream port
- backend container not attached to `${PROXY_NETWORK}`
- backend container unhealthy

Checks:

```bash
docker network inspect ${PROXY_NETWORK}
docker ps
docker logs --tail 100 nginx-proxy-manager
docker logs --tail 100 seerr
```

### `https://${TAILSCALE_IP}` fails

Usually normal.

Likely explanation:

- TLS requires the hostname for certificate and virtual-host matching

### NPM is up, but nothing listens on `80` or `443`

Likely causes:

- NPM container failed to start
- host port collision
- compose deployment failed

Checks:

```bash
docker ps --filter name=nginx-proxy-manager
docker logs --tail 100 nginx-proxy-manager
sudo ss -lntup | egrep ':(80|443)\b'
```

### It worked before reboot and now does not

Likely causes:

- port binding was tied to the Tailscale IP instead of the host
- Docker started before `tailscale0` became ready

Checks:

- confirm compose file uses `80:80` and `443:443`
- confirm UFW, not host IP binding, is enforcing privacy

## Recovery Procedure

Use this order if proxied services stop working:

1. Confirm Pi-hole still resolves the hostname to `${TAILSCALE_IP}`.
2. Confirm the host is listening on `80` and `443`.
3. Confirm `nginx-proxy-manager` is running.
4. Confirm NPM is attached to `${PROXY_NETWORK}`.
5. Test the hostname with `curl --resolve`.
6. Inspect the NPM proxy host entry for the exact domain, upstream host, and upstream port.
7. Confirm the backend container is healthy and reachable on `${PROXY_NETWORK}`.

## Notes

- NPM is the routing layer, not the DNS layer.
- Pi-hole and NPM must both be correct for a service hostname to work.
- A wildcard DNS rule makes names resolve, but NPM still needs one proxy host entry per service hostname.

## Related Docs

- [../CLOUDFLARE.md](../CLOUDFLARE.md)
- [docs/NETWORKING.md](../NETWORKING.md)
- [docs/stacks/pihole.md](pihole.md)
- [docs/OPERATIONS.md](../OPERATIONS.md)
