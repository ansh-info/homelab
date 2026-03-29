# homelab

[![Validate Docker Compose Stacks](https://github.com/ansh-info/homelab/actions/workflows/docker-compose-validate.yml/badge.svg)](https://github.com/ansh-info/homelab/actions/workflows/docker-compose-validate.yml)
[![Validate AeroSpace Config](https://github.com/ansh-info/homelab/actions/workflows/validate-aerospace-config.yml/badge.svg)](https://github.com/ansh-info/homelab/actions/workflows/validate-aerospace-config.yml)
[![Release](https://github.com/ansh-info/homelab/actions/workflows/release.yml/badge.svg)](https://github.com/ansh-info/homelab/actions/workflows/release.yml)

![🦞 OpenClaw](https://img.shields.io/badge/%F0%9F%A6%9E%20OpenClaw-Deployed-2f855a?style=flat-square)
![Portainer](https://img.shields.io/badge/Portainer-Deployed-13BEF9?style=flat-square&logo=portainer&logoColor=white)
![Nginx Proxy Manager](https://img.shields.io/badge/Nginx%20Proxy%20Manager-Deployed-F15833?style=flat-square&logo=nginxproxymanager&logoColor=white)
![Pi-hole](https://img.shields.io/badge/Pi--hole-Deployed-96060C?style=flat-square&logo=pi-hole&logoColor=white)
![Tailscale](https://img.shields.io/badge/Tailscale-Private%20Access-1A73E8?style=flat-square&logo=tailscale&logoColor=white)
![📷 Immich](https://img.shields.io/badge/%F0%9F%93%B7%20Immich-Deployed-4250AF?style=flat-square)
![Nextcloud](https://img.shields.io/badge/Nextcloud-Deployed-0082C9?style=flat-square&logo=nextcloud&logoColor=white)
![Jellyfin](https://img.shields.io/badge/Jellyfin-Deployed-5A2D81?style=flat-square&logo=jellyfin&logoColor=white)
![🗼 Watchtower](https://img.shields.io/badge/%F0%9F%97%BC%20Watchtower-Deployed-4169E1?style=flat-square)
![Docker](https://img.shields.io/badge/Docker-Compose%20Stacks-2496ED?style=flat-square&logo=docker&logoColor=white)

This repository is the source of truth for rebuilding and operating my personal homelab. It documents the host layout, Portainer-managed Docker stacks, private networking model, storage paths, and service-to-service dependencies that make the environment work.

The system is private-first. Services are not published individually to the internet. They are reached through Tailscale, resolved by Pi-hole, and routed by Nginx Proxy Manager over a shared Docker network.

## Architecture Summary

The core request flow is:

1. A client joins the tailnet through Tailscale.
2. Pi-hole resolves `*.homelab.ansh-info.com` to the homelab Tailscale IP.
3. The client connects to the homelab host on `80` or `443`.
4. Nginx Proxy Manager reads the hostname and forwards traffic to the correct container on the shared `proxy` network.
5. The target service responds from its internal container port.

```mermaid
flowchart LR
    Client[Tailscale Client] --> DNS[Pi-hole DNS]
    DNS -->|*.homelab.ansh-info.com -> Tailscale IP| Host[homelab host]
    Host --> NPM[Nginx Proxy Manager]
    NPM --> ProxyNet[Docker proxy network]
    ProxyNet --> Apps[App containers]
```

Core platform components:

- `Tailscale` for private network access
- `Pi-hole` for internal DNS and wildcard local records
- `Nginx Proxy Manager` for hostname-based routing and TLS
- `Docker` plus `Portainer` for stack deployment and operations
- Shared external Docker network `proxy` for reverse-proxied services

## Current Stack Layout

The main service definitions live under [docker-compose](docker-compose):

- [docker-compose/pihole/docker-compose.yml](docker-compose/pihole/docker-compose.yml)
- [docker-compose/nginx-proxy-manager/docker-compose.yml](docker-compose/nginx-proxy-manager/docker-compose.yml)
- [docker-compose/jellyfin-arr-stack/docker-compose.yml](docker-compose/jellyfin-arr-stack/docker-compose.yml)
- [docker-compose/immich/docker-compose.yml](docker-compose/immich/docker-compose.yml)
- [docker-compose/nextcloud-aio/docker-compose.yml](docker-compose/nextcloud-aio/docker-compose.yml)
- [docker-compose/openclaw/docker-compose.yml](docker-compose/openclaw/docker-compose.yml)
- [docker-compose/watchtower/docker-compose.yml](docker-compose/watchtower/docker-compose.yml)

Additional repo content includes dotfiles, editor config, and utility scripts, but the homelab deployment path is centered on the compose files above.

## Rebuild Order

Use this order when rebuilding the machine from scratch:

1. Prepare the Linux host, storage mounts, and baseline packages.
2. Install Docker and Portainer.
3. Install Tailscale and join the machine to the tailnet.
4. Apply firewall rules for the private ingress model.
5. Create the shared external Docker network `proxy`.
6. Prepare stack directories, persistent volumes, and environment files.
7. Deploy Pi-hole.
8. Deploy Nginx Proxy Manager.
9. Restore or recreate internal DNS and proxy host configuration.
10. Deploy application stacks such as Jellyfin/Arr, Immich, Nextcloud AIO, OpenClaw, and Watchtower.
11. Run end-to-end verification for DNS, proxy routing, and service health.

## Documentation Map

Start here for the detailed rebuild docs:

- [docs/README.md](docs/README.md)
- [docs/SETUP.md](docs/SETUP.md)
- [docs/NETWORKING.md](docs/NETWORKING.md)
- [docs/CLOUDFLARE.md](docs/CLOUDFLARE.md)
- [docs/OPERATIONS.md](docs/OPERATIONS.md)
- [docs/VARIABLES.md](docs/VARIABLES.md)
- [docs/stacks/portainer.md](docs/stacks/portainer.md)
- [docs/stacks/pihole.md](docs/stacks/pihole.md)
- [docs/stacks/nginx-proxy-manager.md](docs/stacks/nginx-proxy-manager.md)
- [docs/stacks/jellyfin-arr-stack.md](docs/stacks/jellyfin-arr-stack.md)
- [docs/stacks/immich.md](docs/stacks/immich.md)
- [docs/stacks/nextcloud-aio.md](docs/stacks/nextcloud-aio.md)
- [docs/stacks/openclaw.md](docs/stacks/openclaw.md)
- [docs/stacks/watchtower.md](docs/stacks/watchtower.md)

## Repository Layout

- [docker-compose](docker-compose): Portainer stack definitions and service-specific compose files
- [utils](utils): helper scripts
- [docs](docs): rebuild and operations documentation

## Operating Model

- Primary deployment workflow: `Portainer stacks`
- Secondary fallback workflow: `docker compose` and direct `docker` CLI commands for inspection and recovery
- Internal DNS pattern: wildcard records under `*.homelab.ansh-info.com`
- Access pattern: Tailscale only, with `53`, `80`, and `443` allowed on `tailscale0`

## Status

- Core private ingress path is working through Tailscale, Pi-hole, and NPM.
- Major services are defined as separate compose stacks for easier redeploy and troubleshooting.
- Documentation is being rewritten to make rebuilds deterministic and repeatable.
