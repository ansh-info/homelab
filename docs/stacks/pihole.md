# Pi-hole Stack

This guide documents how Pi-hole is deployed in this homelab, what role it plays in the architecture, how to restore the wildcard DNS behavior, and how to verify it from both the remote host and a local Tailscale client.

For the shared placeholder vocabulary used in this file, see [../VARIABLES.md](../VARIABLES.md).

Reference compose file:

- [docker-compose/pihole/docker-compose.yml](../../docker-compose/pihole/docker-compose.yml)

## Purpose

Pi-hole is the internal DNS authority for the homelab service names. In this setup it has two jobs:

- resolve normal internet domains through upstream DNS
- resolve `*.${DOMAIN_ROOT}` to `${TAILSCALE_IP}` so private services can be reached through Nginx Proxy Manager

Without Pi-hole:

- Tailscale can still provide network connectivity
- but service hostnames like `seerr.${DOMAIN_ROOT}` and `immich.${DOMAIN_ROOT}` will not resolve correctly

Important distinction:

- Pi-hole is the DNS authority for the homelab names
- client devices still need to be told to send `${DOMAIN_ROOT}` queries to Pi-hole
- in this setup, that routing is handled through Tailscale Split DNS

## Dependencies

Pi-hole depends on:

- Docker and Portainer being installed
- the host being connected to Tailscale
- the shared Docker network `${PROXY_NETWORK}` existing
- host port `53/tcp` and `53/udp` being available
- UFW allowing DNS on `tailscale0`
- persistent host directories existing for `/etc/pihole` and `/etc/dnsmasq.d`

Pi-hole is one of the first stacks to deploy. It should come before Nginx Proxy Manager and before any stack that relies on internal hostname-based access.

## Port Binding Warning

Do not bind Pi-hole directly to `${TAILSCALE_IP}:53`.

Avoid patterns like:

```yaml
- "${TAILSCALE_IP}:53:53/tcp"
- "${TAILSCALE_IP}:53:53/udp"
```

Why:

- this creates a boot-time race with `tailscale0`
- Docker may start before the Tailscale interface exists
- Pi-hole can fail to bind port `53` after reboot

Use this instead:

```yaml
- "53:53/tcp"
- "53:53/udp"
```

Then restrict access through UFW on `tailscale0`.

## Placeholder Variables

- `${TAILSCALE_IP}`: homelab Tailscale IP
- `${HOSTNAME}`: Linux hostname of the homelab server
- `${DOMAIN_ROOT}`: internal DNS suffix
- `${PROXY_NETWORK}`: shared Docker network
- `${PIHOLE_ETC_ROOT}`: host path mounted to `/etc/pihole`
- `${PIHOLE_DNSMASQ_ROOT}`: host path mounted to `/etc/dnsmasq.d`
- `${TZ}`: host timezone

## Current Example Values

```text
${TAILSCALE_IP}=100.123.147.108
${HOSTNAME}=homelab
${DOMAIN_ROOT}=homelab.ansh-info.com
${PROXY_NETWORK}=proxy
${PIHOLE_ETC_ROOT}=/mnt/ssd/docker-volumes/pihole/etc-pihole
${PIHOLE_DNSMASQ_ROOT}=/mnt/ssd/docker-volumes/pihole/etc-dnsmasq.d
${TZ}=Asia/Kolkata
```

## Compose Highlights

Current important details from the stack:

- ports exposed:
  - `53:53/tcp`
  - `53:53/udp`
- network:
  - external Docker network `${PROXY_NETWORK}`
- persistent volumes:
  - `${PIHOLE_ETC_ROOT}:/etc/pihole`
  - `${PIHOLE_DNSMASQ_ROOT}:/etc/dnsmasq.d`
- key environment variables:
  - `FTLCONF_webserver_api_password`
  - `FTLCONF_dns_listeningMode=all`
  - `PIHOLE_HOSTNAME`
  - `FTLCONF_misc_etc_dnsmasq_d=true`

## Critical Pi-hole v6 Requirement

If `/etc/dnsmasq.d` is mounted, Pi-hole v6 must be told to load it.

This line must exist in the `environment:` block:

```yaml
FTLCONF_misc_etc_dnsmasq_d: "true"
```

Without it:

- the wildcard config file can exist on disk
- the file can be visible inside the container
- Pi-hole can still ignore it
- local homelab names will not resolve

This exact issue caused the private homelab domains to stop resolving even though Tailscale, NPM, and the backend services were healthy.

## Portainer Deployment

Deploy Pi-hole through Portainer as a stack using the compose file at:

- [docker-compose/pihole/docker-compose.yml](../../docker-compose/pihole/docker-compose.yml)

Before deploying:

1. ensure `${PROXY_NETWORK}` exists
2. ensure `${PIHOLE_ETC_ROOT}` exists
3. ensure `${PIHOLE_DNSMASQ_ROOT}` exists
4. ensure host port `53` is not already blocked by another service

After deployment, confirm the container is healthy:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

## Suggested NPM Proxy Target

If you want the Pi-hole web UI behind NPM, use:

- `pihole.${DOMAIN_ROOT}` -> `pihole:80`

### How To Fill NPM For Pi-hole

Use this proxy-host entry:

| Public hostname | Scheme | Forward Hostname / IP | Forward Port |
| --- | --- | --- | --- |
| `pihole.${DOMAIN_ROOT}` | `http` | `pihole` | `80` |

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

Important:

- this only covers the Pi-hole web UI
- DNS itself still uses port `53` directly and does not go through NPM
- do not confuse Pi-hole DNS traffic with the Pi-hole web interface

## Wildcard DNS Configuration

This homelab uses a wildcard dnsmasq rule so every service under `*.${DOMAIN_ROOT}` resolves to `${TAILSCALE_IP}`.

### Placeholder Form

Create the host file:

```bash
sudo tee ${PIHOLE_DNSMASQ_ROOT}/99-homelab.conf >/dev/null <<'EOF'
address=/.${DOMAIN_ROOT}/${TAILSCALE_IP}
EOF
docker restart pihole
```

### Current Example

This is the exact current example from the working homelab:

```bash
sudo tee /mnt/ssd/docker-volumes/pihole/etc-dnsmasq.d/99-homelab.conf >/dev/null <<'EOF'
address=/.homelab.ansh-info.com/100.123.147.108
EOF
docker restart pihole
```

What this does:

- creates a dnsmasq config file in the mounted Pi-hole config directory
- maps every hostname ending in `.homelab.ansh-info.com` to `100.123.147.108`
- reloads Pi-hole so the rule becomes active

This single rule covers:

- `seerr.homelab.ansh-info.com`
- `immich.homelab.ansh-info.com`
- `jellyfin.homelab.ansh-info.com`
- any future service hostname under the same suffix

## Verifying the Wildcard Config on the Remote Host

Run these commands on `${HOSTNAME}` after creating the file.

### Confirm the file exists on the host

```bash
sudo cat ${PIHOLE_DNSMASQ_ROOT}/99-homelab.conf
```

Expected:

```conf
address=/.${DOMAIN_ROOT}/${TAILSCALE_IP}
```

### Confirm the file is mounted inside the container

```bash
docker exec pihole sh -lc 'ls -la /etc/dnsmasq.d'
docker exec pihole sh -lc 'cat /etc/dnsmasq.d/99-homelab.conf'
```

### Confirm the env var is active inside the container

```bash
docker exec pihole sh -lc 'env | grep FTLCONF_misc_etc_dnsmasq_d'
```

Expected:

```text
FTLCONF_misc_etc_dnsmasq_d=true
```

### Confirm Pi-hole itself resolves a local homelab domain

```bash
docker exec pihole sh -lc 'dig +short seerr.${DOMAIN_ROOT} @127.0.0.1'
docker exec pihole sh -lc 'dig +short immich.${DOMAIN_ROOT} @127.0.0.1'
```

Expected:

```text
${TAILSCALE_IP}
```

### Confirm the host listener exists

```bash
sudo ss -lntup | grep :53
```

### Confirm container health and logs

```bash
docker ps --filter name=pihole
docker logs --tail 100 pihole
```

## Verifying from a Local Tailscale Client

Run these commands from a client machine connected to the tailnet.

Before testing, make sure Tailscale admin DNS includes a Split DNS entry for:

- domain: `${DOMAIN_ROOT}`
- nameserver: `${TAILSCALE_IP}`

### Confirm public DNS works through Pi-hole

```bash
dig +short google.com @${TAILSCALE_IP}
```

Expected:

- returns a public IP for `google.com`

### Confirm private homelab DNS works through Pi-hole

```bash
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
dig +short immich.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

Expected:

```text
${TAILSCALE_IP}
```

### Confirm the local machine resolver now sees the hostname

```bash
dig +short seerr.${DOMAIN_ROOT}
dscacheutil -q host -a name seerr.${DOMAIN_ROOT}
```

On macOS, if stale DNS is cached, flush it:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Then re-test:

```bash
dig +short seerr.${DOMAIN_ROOT}
```

If local resolution is still empty, compare local resolver behavior with direct Pi-hole queries:

```bash
dig +short immich.${DOMAIN_ROOT}
dig +short immich.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

Interpretation:

- if direct `@${TAILSCALE_IP}` works but the plain lookup does not, the client is not routing `${DOMAIN_ROOT}` queries to Pi-hole correctly
- in this homelab, the expected fix is restoring the Tailscale Split DNS entry for `${DOMAIN_ROOT}` -> `${TAILSCALE_IP}`

## UFW Expectations

Pi-hole depends on these allow rules on `tailscale0`:

```bash
sudo ufw allow in on tailscale0 to any port 53 proto tcp
sudo ufw allow in on tailscale0 to any port 53 proto udp
```

Verify:

```bash
sudo ufw status verbose
```

## Common Failure Modes

### Public DNS works, but `seerr.${DOMAIN_ROOT}` returns nothing

Likely causes:

- wildcard dnsmasq file missing
- wildcard file mounted but not loaded
- `FTLCONF_misc_etc_dnsmasq_d` missing
- local machine not using the expected DNS path

Checks:

```bash
docker exec pihole sh -lc 'dig +short seerr.${DOMAIN_ROOT} @127.0.0.1'
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

### Wildcard file exists, but Pi-hole still returns nothing

Likely causes:

- `FTLCONF_misc_etc_dnsmasq_d` not set to `true`
- Pi-hole not restarted or redeployed after the config change
- syntax error in the dnsmasq file

Checks:

```bash
docker exec pihole sh -lc 'env | grep FTLCONF_misc_etc_dnsmasq_d'
docker exec pihole sh -lc 'cat /etc/dnsmasq.d/99-homelab.conf'
docker logs --tail 100 pihole
```

### Port 53 is already in use

Likely causes:

- another DNS service is binding the port
- host resolver stub listener conflict

Checks:

```bash
sudo ss -lntup | grep :53
```

### Pi-hole container is healthy, but clients still do not resolve the names

Likely causes:

- client machine is not querying Pi-hole
- client has stale cache
- firewall is blocking DNS on `tailscale0`

Checks:

```bash
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
sudo ufw status verbose
```

## Recovery Procedure

Use this order if private service names stop resolving:

1. Confirm `docker ps` shows `pihole` running.
2. Confirm `sudo ss -lntup | grep :53` shows listeners on port `53`.
3. Confirm the wildcard file exists on the host.
4. Confirm the same file is visible inside the container.
5. Confirm `FTLCONF_misc_etc_dnsmasq_d=true` is active.
6. Query Pi-hole locally with `@127.0.0.1`.
7. Query Pi-hole remotely with `@${TAILSCALE_IP}`.
8. Flush DNS cache on the client if needed.

## Notes

- Pi-hole is the DNS layer, not the reverse proxy.
- NPM still needs matching proxy host entries for each service hostname.
- The wildcard DNS rule only makes names resolve. It does not create proxy routes.

## Related Docs

- [docs/NETWORKING.md](../NETWORKING.md)
- [docs/SETUP.md](../SETUP.md)
- [docs/stacks/nginx-proxy-manager.md](nginx-proxy-manager.md)
