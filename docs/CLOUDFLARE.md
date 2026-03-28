# Cloudflare and Certificates

This guide explains how Cloudflare is used in the homelab, how Nginx Proxy Manager obtains certificates, and how that fits with the private Tailscale plus Pi-hole access model.

For the shared placeholder vocabulary used in this file, see [VARIABLES.md](VARIABLES.md).

## What Cloudflare Does Here

Cloudflare is not the private DNS engine for the homelab service names.

In this setup:

- Pi-hole answers private DNS queries for `*.${DOMAIN_ROOT}`
- Tailscale Split DNS tells clients to send `${DOMAIN_ROOT}` queries to Pi-hole at `${TAILSCALE_IP}`
- Nginx Proxy Manager terminates TLS and routes traffic
- Cloudflare owns the parent public domain and is used by NPM for certificate issuance

So the roles are:

- `Cloudflare`: domain ownership and DNS challenge provider
- `Pi-hole`: private resolver for homelab services
- `NPM`: TLS termination and reverse proxying

## Certificate Model

The current homelab uses Let's Encrypt certificates in Nginx Proxy Manager.

Important detail:

- the certificate is issued by `Let's Encrypt`
- Cloudflare is used as the DNS provider for the DNS challenge
- this is not a Cloudflare Origin Certificate setup

This is why NPM needs Cloudflare API credentials.

## Why DNS Challenge Is the Right Fit

The homelab is private-first and services are not individually exposed to the public internet.

That makes DNS challenge the correct certificate path because:

- no public HTTP challenge endpoint is needed
- the services can stay private behind Tailscale
- NPM can still obtain and renew certificates for `*.${DOMAIN_ROOT}`

## Prerequisites

Before creating certificates in NPM:

1. the parent domain exists in Cloudflare
2. you have Cloudflare API credentials that NPM can use
3. NPM is running and reachable
4. the intended service names are part of the same domain namespace

Current example:

- parent domain: `ansh-info.com`
- internal suffix: `homelab.ansh-info.com`
- wildcard certificate target: `*.homelab.ansh-info.com`

## Recommended Certificate in NPM

For this homelab, the clean default is a wildcard certificate covering:

- `*.${DOMAIN_ROOT}`

With current example values:

- `*.homelab.ansh-info.com`

You may also choose to include:

- `${DOMAIN_ROOT}`

if you want the base subdomain itself covered as well.

## How to Create the Certificate

In NPM:

1. Go to `SSL Certificates`
2. Create a new `Let's Encrypt` certificate
3. Enter the domain names:
   - `*.${DOMAIN_ROOT}`
   - optionally `${DOMAIN_ROOT}`
4. Choose the Cloudflare DNS challenge method
5. Enter the Cloudflare credentials required by NPM
6. Save and let NPM request the certificate

Current example:

- `*.homelab.ansh-info.com`
- optional `homelab.ansh-info.com`

## How to Use the Certificate in Proxy Hosts

Once the wildcard certificate exists, each proxy host can select it from the SSL tab.

Current working pattern:

- SSL certificate: `*.${DOMAIN_ROOT}`
- `Force SSL`: enabled
- `HTTP/2 Support`: enabled
- `HSTS Enabled`: enabled
- `HSTS Sub-domains`: enabled

With current example values, the selected certificate appears as:

- `*.homelab.ansh-info.com`

## Important Clarifications

### You do not need one certificate per service

Because the setup uses a wildcard certificate, one certificate can cover:

- `seerr.${DOMAIN_ROOT}`
- `radarr.${DOMAIN_ROOT}`
- `sonarr.${DOMAIN_ROOT}`
- `bazarr.${DOMAIN_ROOT}`
- `immich.${DOMAIN_ROOT}`
- `jellyfin.${DOMAIN_ROOT}`
- `nextcloud.${DOMAIN_ROOT}`
- `nextcloud-admin.${DOMAIN_ROOT}`

### You still need one proxy host per service

The wildcard certificate only covers TLS.

It does not create the actual routing rules.

NPM still needs a separate proxy host entry for each hostname.

## Interaction With Private DNS

Certificate issuance and private resolution are separate concerns:

- Cloudflare plus Let's Encrypt handles certificate issuance
- Pi-hole handles private DNS answers
- Tailscale Split DNS makes clients use Pi-hole for `${DOMAIN_ROOT}`

This means:

- a valid wildcard certificate does not make a service resolve
- a working Pi-hole wildcard DNS rule does not create a certificate
- both must exist for a smooth HTTPS experience

## Local Verification

From a Tailscale client:

```bash
dig +short seerr.${DOMAIN_ROOT}
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
```

Expected:

- DNS resolves to `${TAILSCALE_IP}`
- TLS succeeds
- the certificate matches the hostname

## Related Guides

- [NETWORKING.md](NETWORKING.md)
- [stacks/nginx-proxy-manager.md](stacks/nginx-proxy-manager.md)
- [stacks/pihole.md](stacks/pihole.md)
