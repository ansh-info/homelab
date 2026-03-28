# Homelab Documentation

This directory contains the rebuild and operations guides for the homelab. The primary audience is me rebuilding the system from scratch on a fresh machine, with enough detail that the setup is still understandable later or transferable to another host.

## Reading Order

Use the docs in this order for a full rebuild:

1. [SETUP.md](SETUP.md)
2. [NETWORKING.md](NETWORKING.md)
3. [VARIABLES.md](VARIABLES.md)
4. Stack docs in [docs/stacks](stacks)
5. [OPERATIONS.md](OPERATIONS.md)

## Shared Guides

- [SETUP.md](SETUP.md): host bootstrap, Docker, Portainer, Tailscale, storage, firewall, and shared network preparation
- [NETWORKING.md](NETWORKING.md): DNS, Tailscale, Pi-hole, Nginx Proxy Manager, routing flow, and troubleshooting model
- [CLOUDFLARE.md](CLOUDFLARE.md): Cloudflare DNS ownership, wildcard certificate issuance, and how certificates are used in NPM
- [VARIABLES.md](VARIABLES.md): shared placeholder variables and current example values
- [OPERATIONS.md](OPERATIONS.md): day-two operations, backups, redeploys, and incident recovery

## Stack Guides

- [stacks/portainer.md](stacks/portainer.md)
- [stacks/pihole.md](stacks/pihole.md)
- [stacks/nginx-proxy-manager.md](stacks/nginx-proxy-manager.md)
- [stacks/jellyfin-arr-stack.md](stacks/jellyfin-arr-stack.md)
- [stacks/immich.md](stacks/immich.md)
- [stacks/nextcloud-aio.md](stacks/nextcloud-aio.md)
- [stacks/watchtower.md](stacks/watchtower.md)

## Documentation Conventions

- Placeholder variables are used for host-specific values, such as `${DATA_ROOT}`, `${TAILSCALE_IP}`, and `${DOMAIN_ROOT}`.
- Each guide should include a concrete example section showing the current values used on the existing homelab.
- Portainer is the primary deployment path. Raw `docker` and `docker compose` commands are documented as fallback and debugging tools.
- Shared concepts should be documented once in a shared guide and referenced from stack-specific docs.
