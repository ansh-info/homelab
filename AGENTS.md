# AGENTS

This file is for coding and automation agents working in this repository. It explains the repo structure, operational invariants, and the update rules that should be followed when changing homelab configuration or documentation.

## Purpose

This repository is the source of truth for rebuilding and operating the homelab.

The repo is not just a collection of compose files. It also captures:

- the private networking model
- the storage layout
- the Portainer deployment model
- the service-specific operational conventions
- the documentation needed to reproduce the setup

Agents should optimize for:

- preserving working homelab behavior
- keeping the repo reproducible
- updating docs whenever config conventions change

## Architecture

The current private access path is:

1. Tailscale provides private network connectivity to the homelab host.
2. Tailscale Split DNS sends `${DOMAIN_ROOT}` queries to Pi-hole.
3. Pi-hole resolves `*.${DOMAIN_ROOT}` to the homelab Tailscale IP.
4. Nginx Proxy Manager accepts traffic on `80` and `443`.
5. NPM routes the request to the correct backend container on the shared Docker `proxy` network.

Core components:

- `Tailscale`: private network path
- `Pi-hole`: DNS authority for homelab service names
- `Nginx Proxy Manager`: hostname-based reverse proxy and TLS termination
- `Portainer`: primary deployment and operations interface
- `Docker`: container runtime

## Repo Layout

Key directories:

- `docker-compose/`: compose definitions grouped by stack
- `docs/`: rebuild, networking, operations, and stack docs
- `docs/stacks/`: stack-specific docs
- `utils/`: helper scripts

Current stack layout:

- `docker-compose/pihole`
- `docker-compose/nginx-proxy-manager`
- `docker-compose/jellyfin-arr-stack`
- `docker-compose/immich`
- `docker-compose/nextcloud-aio`
- `docker-compose/watchtower`

If a new stack is added, place it under:

- `docker-compose/<stack-name>/docker-compose.yml`

If the stack needs an env file, keep it in the same folder.

## Deployment Model

Primary deployment path:

- `Portainer stacks`

Fallback and verification path:

- `docker compose`
- `docker`

Agents should preserve the Portainer-first operating model unless the user explicitly changes that design.

## Storage Rules

Persistent bind-mounted service data belongs under:

- `/mnt/ssd/docker-volumes/<stack-or-service>/...`

Examples:

- `/mnt/ssd/docker-volumes/pihole/etc-pihole`
- `/mnt/ssd/docker-volumes/nginx-proxy-manager/data`
- `/mnt/ssd/docker-volumes/immich/library`
- `/mnt/ssd/docker-volumes/nextcloud/data`
- `/mnt/ssd/docker-volumes/arr/radarr/config`

Do not introduce new scattered storage roots like:

- `/mnt/ssd/arr`
- `/mnt/ssd/immich`
- `/mnt/ssd/npm`
- `/mnt/ssd/nextcloud`

Ownership should be service-appropriate. Do not force one owner on all service directories.

Examples:

- Nextcloud data may require `33:33`
- other services may preserve existing service-specific ownership from the original data

Docker engine internal state is expected to use the default Docker root again:

- `/var/lib/docker`

This should not be confused with service bind mounts under `/mnt/ssd/docker-volumes/...`.

## Networking Rules

### Shared Proxy Network

Reverse-proxied services should join:

- `proxy`

If a service should be available through NPM, the service must:

- be attached to `proxy`
- have a stable container name or upstream hostname
- expose the correct internal service port

### Do Not Bind to the Tailscale IP

Do not bind service ports directly to the Tailscale IP like:

```yaml
- "100.123.147.108:80:80"
```

Use standard bindings like:

```yaml
- "80:80"
```

and restrict ingress with UFW on `tailscale0`.

This avoids the boot-time race condition where Docker starts before `tailscale0` exists.

### Tailscale Split DNS

The current client DNS model depends on Tailscale Split DNS:

- domain: `${DOMAIN_ROOT}`
- nameserver: `${TAILSCALE_IP}`

Pi-hole remains the DNS authority, but Tailscale Split DNS tells clients to send those queries to Pi-hole.

## NPM Rules

### General Pattern

Each public hostname needs its own NPM proxy host entry.

The wildcard certificate pattern is:

- `*.${DOMAIN_ROOT}`

Standard NPM toggles in this homelab:

- `Access List`: `Publicly Accessible`
- `Cache Assets`: enabled
- `Block Common Exploits`: enabled
- `Websockets Support`: enabled
- `Force SSL`: enabled
- `HTTP/2 Support`: enabled
- `HSTS Enabled`: enabled
- `HSTS Sub-domains`: enabled

### Upstream Scheme Rules

Most services use:

- scheme: `http`

Known exception:

- `portainer.${DOMAIN_ROOT}` -> `https://portainer:9443`

Known special case:

- Nextcloud AIO uses two hosts:
  - `nextcloud-admin.${DOMAIN_ROOT}` -> `nextcloud-aio-mastercontainer:8080`
  - `nextcloud.${DOMAIN_ROOT}` -> `nextcloud-aio-apache:11000`

### Certificate Guidance

Certificate issuance details live in:

- `docs/CLOUDFLARE.md`

Do not document Cloudflare as the private DNS authority for homelab services. That role belongs to Pi-hole.

## Service Addition Rules

When adding a new service, agents should decide all of the following explicitly:

1. Which stack should own the service?
2. What host bind-mount paths will it use under `/mnt/ssd/docker-volumes/...`?
3. Should it be reverse-proxied through NPM?
4. Should it join the shared `proxy` network?
5. What public hostname should it use, if any?
6. What internal service port should NPM target?
7. Does it need a stack-specific doc update or a new stack doc?

### Default Pattern for New Reverse-Proxied Services

For a typical new internal web service:

- create a bind-mount path under `/mnt/ssd/docker-volumes/<stack>/<service>/...`
- attach it to `proxy`
- keep the app internal port unexposed if NPM is the intended entrypoint
- add an NPM host like `<service>.${DOMAIN_ROOT}`
- use the wildcard certificate
- document the mapping in the relevant stack doc

### If a New Top-Level Stack Is Added

Also update:

- `README.md`
- `docs/README.md`
- stack-specific docs under `docs/stacks/`
- `docs/VARIABLES.md` if new placeholders are introduced
- `.github/workflows/docker-compose-validate.yml`

## Documentation Update Rules

Whenever config changes affect how the homelab is rebuilt or operated, update the docs in the same change.

Examples:

- if storage paths change, update the related stack docs and `docs/VARIABLES.md`
- if compose paths change, update repo docs and CI
- if a new proxy host pattern is introduced, update `docs/stacks/nginx-proxy-manager.md`
- if certificate behavior changes, update `docs/CLOUDFLARE.md`
- if networking assumptions change, update `docs/NETWORKING.md`

Do not leave repo docs behind the live compose layout.

## Release Conventions

This repo uses conventional-commit style messages so semantic releases can determine the next version automatically.

Use these commit types:

- `feat:` for new functionality or new services
- `fix:` for bug fixes and behavior corrections
- `docs:` for documentation-only changes
- `chore:` for maintenance tasks
- `ci:` for workflow changes
- `refactor:` for non-behavioral code or config restructuring

Version bump rules:

- `fix:` -> patch bump
- `feat:` -> minor bump
- `feat!:` or `fix!:` or `BREAKING CHANGE:` footer -> major bump

Examples:

- `feat: add uptime kuma stack`
- `fix: correct nextcloud aio upstream port`
- `docs: expand npm proxy host guide`

Documentation-only and maintenance commits may still appear in release notes, but the meaningful version bumps should come from `feat`, `fix`, and explicit breaking changes.

## Verification Checklist

Before claiming a stack change is complete:

1. Run `docker compose config` for the changed stack.
2. Search for stale paths or removed directory names with `rg`.
3. Check that compose files and docs agree.
4. If the service is DNS or proxy sensitive, verify end-to-end behavior.

Useful checks:

```bash
docker compose config
rg -n 'old-path-or-old-name' docker-compose docs README.md
docker network inspect proxy
```

Examples of end-to-end checks:

```bash
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
```

## Known Exceptions

### Pi-hole

- Pi-hole v6 needs:

```yaml
FTLCONF_misc_etc_dnsmasq_d: "true"
```

to load `/etc/dnsmasq.d`.

### Portainer

- Portainer normally runs behind NPM on the `proxy` network without published host ports.
- Recovery mode may temporarily publish:
  - `9443`
  - `8000`

### Nextcloud AIO

- uses separate admin and app hostnames
- data path is currently under:
  - `/mnt/ssd/docker-volumes/nextcloud/data`

### Jellyfin GPU

The current Jellyfin config assumes NVIDIA runtime support on the host.

That includes:

- `runtime: nvidia`
- `NVIDIA_VISIBLE_DEVICES=all`
- `NVIDIA_DRIVER_CAPABILITIES=compute,video,utility`

Agents should not remove or rewrite this casually.

## Source Docs

For deeper context, read:

- `README.md`
- `docs/README.md`
- `docs/SETUP.md`
- `docs/NETWORKING.md`
- `docs/CLOUDFLARE.md`
- `docs/OPERATIONS.md`
- `docs/stacks/*.md`
