# Networking

This guide documents how traffic reaches the homelab and how private service names are resolved. It is the core reference for understanding the dependency chain between Tailscale, Pi-hole, Nginx Proxy Manager, Docker networking, and the application containers.

For the shared placeholder vocabulary used in this file, see [VARIABLES.md](VARIABLES.md).

## Scope

This guide explains:

- how clients reach the homelab host
- how `*.homelab.ansh-info.com` resolves internally
- how Nginx Proxy Manager routes traffic to the right container
- what role Cloudflare plays in the naming model
- how to diagnose failures layer by layer

## Placeholder Variables

- `${TAILSCALE_IP}`: Tailscale IPv4 of the homelab host
- `${DOMAIN_ROOT}`: internal service suffix, for example `homelab.ansh-info.com`
- `${PROXY_NETWORK}`: shared external Docker network, currently `proxy`

## Current Example Values

```text
${TAILSCALE_IP}=100.123.147.108
${DOMAIN_ROOT}=homelab.ansh-info.com
${PROXY_NETWORK}=proxy
```

## Component Hierarchy

For private service access, the dependency order is:

1. `Tailscale`
2. `Pi-hole`
3. `Nginx Proxy Manager`
4. Docker network `${PROXY_NETWORK}`
5. Backend application containers
6. Cloudflare-managed domain naming

This order matters during troubleshooting:

- if Tailscale fails, private access fails completely
- if Pi-hole fails, names stop resolving but direct IP tests may still work
- if NPM fails, DNS works but hostname routing breaks
- if a backend container fails, only that service breaks

## Request Flow

The normal request flow is:

1. A client device joins the tailnet through Tailscale.
2. The client sends a DNS query for a hostname like `seerr.${DOMAIN_ROOT}`.
3. Pi-hole answers with `${TAILSCALE_IP}`.
4. The client opens `https://${TAILSCALE_IP}` while sending the hostname `seerr.${DOMAIN_ROOT}` in the request.
5. Nginx Proxy Manager accepts the TLS connection and reads the hostname through SNI and the HTTP host header.
6. NPM matches that hostname to a proxy host definition.
7. NPM forwards the request over the Docker `${PROXY_NETWORK}` to the target container and port.

```mermaid
flowchart LR
    Client[Tailscale client] --> Query[DNS query for service hostname]
    Query --> PiHole[Pi-hole]
    PiHole -->|returns ${TAILSCALE_IP}| Host[homelab host]
    Host -->|80/443 with hostname| NPM[Nginx Proxy Manager]
    NPM --> ProxyNet[Docker ${PROXY_NETWORK}]
    ProxyNet --> Seerr[seerr:5055]
    ProxyNet --> Immich[immich_server:2283]
    ProxyNet --> Jellyfin[jellyfin:8096]
```

## Role of Each Component

### Tailscale

Tailscale provides the private network path to the homelab host. In this setup, the important behavior is:

- clients can reach `${TAILSCALE_IP}`
- the host can limit inbound access to `tailscale0`
- services do not need to be exposed directly to the public internet

Tailscale is not the DNS authority for the homelab subdomains in this setup. It only provides the transport path.

For client devices, Tailscale also provides the DNS routing layer when Split DNS is configured in the Tailscale admin panel.

Current client-side DNS routing model:

- Split DNS domain: `${DOMAIN_ROOT}`
- nameserver: `${TAILSCALE_IP}`

That means Tailscale clients are told:

- for names under `${DOMAIN_ROOT}`, send DNS queries to Pi-hole at `${TAILSCALE_IP}`

This is important because:

- Pi-hole remains the source of truth for `*.${DOMAIN_ROOT}`
- Tailscale Split DNS tells client devices where to ask
- removing the Split DNS entry can break client resolution even if Pi-hole itself is healthy

### Pi-hole

Pi-hole is the internal DNS authority for the homelab service names. Its key job is to return `${TAILSCALE_IP}` for hostnames under `${DOMAIN_ROOT}`.

The current wildcard model is:

```conf
address=/.${DOMAIN_ROOT}/${TAILSCALE_IP}
```

With the current example values, this becomes:

```conf
address=/.homelab.ansh-info.com/100.123.147.108
```

That single rule covers:

- `seerr.homelab.ansh-info.com`
- `immich.homelab.ansh-info.com`
- `jellyfin.homelab.ansh-info.com`
- any other hostname under `*.homelab.ansh-info.com`

### Nginx Proxy Manager

NPM is the hostname-based reverse proxy. It listens on `80` and `443` on the host and routes traffic based on the requested hostname.

Examples:

- `seerr.${DOMAIN_ROOT}` -> `seerr:5055`
- `immich.${DOMAIN_ROOT}` -> `immich_server:2283`
- `jellyfin.${DOMAIN_ROOT}` -> `jellyfin:8096`

NPM depends on:

- DNS resolving service names to `${TAILSCALE_IP}`
- backend containers being attached to `${PROXY_NETWORK}`
- the proxy host definitions being present in the NPM UI

### Docker `${PROXY_NETWORK}`

The shared external Docker network lets NPM reach backend containers by container name. If the network is missing or a service is not attached to it, the proxy host can exist but routing still fails.

### Application Containers

The backend applications only need to listen on their internal ports and join `${PROXY_NETWORK}` when they are meant to be reverse-proxied. Most of them do not need public host port mappings because NPM handles ingress for them.

### Cloudflare and the Domain

Cloudflare matters here as the owner of the parent domain `ansh-info.com`, but in the private access path it is not doing the main work. The actual private name resolution is being handled by Pi-hole.

Cloudflare in this setup is best understood as:

- the public naming anchor for the domain
- the source of certificate validation context for NPM
- not the internal DNS engine for tailnet-only hostnames

## Wildcard DNS Model

The homelab relies on a wildcard local DNS rule rather than one manually entered record per service.

Current file:

```text
${PIHOLE_DNSMASQ_ROOT}/99-homelab.conf
```

Current content:

```conf
address=/.homelab.ansh-info.com/100.123.147.108
```

Why this matters:

- new service hostnames start resolving immediately without adding records one by one
- Pi-hole stays the single DNS control point for the internal service namespace
- the DNS layer remains independent from NPM proxy-host creation

Important Pi-hole v6 note:

If `/etc/dnsmasq.d` is mounted into the Pi-hole container, Pi-hole v6 must be told to load it:

```yaml
FTLCONF_misc_etc_dnsmasq_d: "true"
```

Without that environment variable:

- the wildcard config file can exist on disk
- the volume mount can work correctly
- the DNS rule can still be ignored

The stack-specific recovery commands for this live in [stacks/pihole.md](stacks/pihole.md).

## Client DNS Routing Requirement

For this homelab, wildcard DNS on Pi-hole is necessary but not sufficient on its own. Client devices still need to know to send `${DOMAIN_ROOT}` queries to Pi-hole.

The current working solution is Tailscale Split DNS in the admin panel:

- domain: `${DOMAIN_ROOT}`
- nameserver: `${TAILSCALE_IP}`

With current example values:

- domain: `homelab.ansh-info.com`
- nameserver: `100.123.147.108`

What happens if this is removed:

- `dig +short immich.${DOMAIN_ROOT} @${TAILSCALE_IP}` may still work
- `dig +short immich.${DOMAIN_ROOT}` on the client may return nothing
- browsers stop resolving homelab service names normally

Local client verification:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
dig +short immich.${DOMAIN_ROOT}
dig +short immich.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

Expected:

```text
${TAILSCALE_IP}
```

## Race Condition and Port Binding Design

This homelab previously hit a boot-time race condition caused by binding Docker ports directly to the Tailscale IP instead of binding to the host and restricting access with UFW.

### Fragile pattern

These kinds of bindings are fragile:

```yaml
- "100.123.147.108:53:53/tcp"
- "100.123.147.108:53:53/udp"
- "100.123.147.108:80:80"
- "100.123.147.108:443:443"
```

Why this breaks:

- Docker can start before `tailscale0` exists after reboot
- the Tailscale IP is not yet present when Docker tries to bind
- the container fails to start or fails to publish the required port

### Stable pattern

The stable design is:

```yaml
- "53:53/tcp"
- "53:53/udp"
- "80:80"
- "443:443"
```

Then restrict access at the firewall layer:

```bash
sudo ufw allow in on tailscale0 to any port 53 proto tcp
sudo ufw allow in on tailscale0 to any port 53 proto udp
sudo ufw allow in on tailscale0 to any port 80 proto tcp
sudo ufw allow in on tailscale0 to any port 443 proto tcp
```

This works better because:

- Docker no longer depends on the Tailscale interface already existing
- services bind reliably on boot
- UFW still enforces the private ingress boundary

### Resolver conflict that often appears alongside this issue

When Pi-hole owns port `53`, the host must not keep a conflicting stub listener on `53`.

The stable resolver design is:

- keep `systemd-resolved` enabled
- set `DNSStubListener=no`
- point host DNS at `127.0.0.1`
- prevent Tailscale DNS override from breaking that path if needed

Host-side details for that live in [SETUP.md](SETUP.md).

## TLS and SNI Behavior

This setup only works correctly when clients use the hostname, not just the raw IP.

Expected behavior:

- `https://seerr.${DOMAIN_ROOT}` works
- `https://${TAILSCALE_IP}` may fail with a TLS error like `unrecognized name`

That is normal.

Reason:

- the TLS certificate is issued for hostnames like `*.${DOMAIN_ROOT}`
- NPM uses SNI and the hostname to select the correct certificate and proxy host
- a raw IP request does not provide the expected hostname context

This is why a test like this is valid:

```bash
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
```

And this may fail even when everything is healthy:

```bash
curl -vk https://${TAILSCALE_IP}
```

## Firewall Model

The intended firewall model is:

- allow `53/tcp` and `53/udp` on `tailscale0` for Pi-hole
- allow `80/tcp` and `443/tcp` on `tailscale0` for NPM
- keep default inbound policy as deny
- allow SSH only from trusted Tailscale clients

Example verification:

```bash
sudo ufw status verbose
sudo ss -lntup | egrep ':(53|80|443)\b'
```

## Common Verification Commands

Use these commands to validate each layer.

### Tailscale Reachability

```bash
tailscale status
tailscale ping ${TAILSCALE_IP}
```

### Pi-hole DNS

```bash
dig +short google.com @${TAILSCALE_IP}
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
dig +short immich.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

Expected:

- public names like `google.com` return public IPs
- internal names like `seerr.${DOMAIN_ROOT}` return `${TAILSCALE_IP}`

### Reverse Proxy Routing

```bash
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
curl -vk --resolve immich.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://immich.${DOMAIN_ROOT}/
```

### Host Listeners

```bash
sudo ss -lntup | egrep ':(53|80|443)\b'
```

### Docker Network Membership

```bash
docker network inspect ${PROXY_NETWORK}
```

## Failure Model

Use this section to identify the broken layer quickly.

### Symptom: no private service is reachable

Check first:

- `tailscale status`
- `tailscale ping ${TAILSCALE_IP}`

Likely causes:

- client not connected to the tailnet
- host offline in Tailscale
- host firewall or routing issue
- service failed to bind on boot because it was tied directly to the Tailscale IP

### Symptom: direct IP works but service hostname does not resolve

Check:

```bash
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

Likely causes:

- Pi-hole wildcard or local DNS record missing
- Pi-hole not loading `/etc/dnsmasq.d`
- local machine using the wrong DNS server

### Symptom: hostname resolves but site still fails

Check:

```bash
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
```

Likely causes:

- NPM proxy host missing or misconfigured
- backend container not healthy
- backend container not attached to `${PROXY_NETWORK}`
- wrong upstream port in NPM

### Symptom: `https://${TAILSCALE_IP}` fails with TLS errors

This is usually normal, not a failure.

Likely explanation:

- request is missing the hostname needed for certificate selection and proxy routing

### Symptom: NPM default page appears

Likely causes:

- hostname was not matched to any NPM proxy host
- request reached NPM but the proxy host entry is missing
- DNS name or browser request does not match the configured host entry exactly

### Symptom: public DNS works but homelab names do not

Likely causes:

- wildcard Pi-hole rule missing
- Pi-hole custom dnsmasq files ignored
- Pi-hole config volume mounted but not being loaded

### Symptom: DNS looks correct but upstream service is unreachable

Check:

```bash
docker ps
docker logs --tail 100 nginx-proxy-manager
docker logs --tail 100 <service-name>
docker network inspect ${PROXY_NETWORK}
```

Likely causes:

- container unhealthy
- service listening on a different port than NPM expects
- service not joined to `${PROXY_NETWORK}`

## Canonical Recovery Sequence

When debugging, use this order:

1. Confirm Tailscale connectivity to `${TAILSCALE_IP}`.
2. Confirm Pi-hole answers internal names with `${TAILSCALE_IP}`.
3. Confirm host is listening on `53`, `80`, and `443`.
4. Confirm NPM receives hostname-based requests successfully.
5. Confirm target container is healthy and attached to `${PROXY_NETWORK}`.

This sequence prevents guessing and keeps each failure isolated to a specific layer.

## Related Docs

- [SETUP.md](SETUP.md)
- [stacks/pihole.md](stacks/pihole.md)
- [stacks/nginx-proxy-manager.md](stacks/nginx-proxy-manager.md)
- [OPERATIONS.md](OPERATIONS.md)
