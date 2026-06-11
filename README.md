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

```
                         HOMELAB NETWORK ARCHITECTURE
===============================================================================

  TAILSCALE CLIENTS (on private WireGuard mesh)
  +------------------+  +------------------+  +------------------+
  | MacBook (Work)   |  | MacBook (Personal)|  | iPhone 16 Pro   |
  | macOS            |  | macOS             |  | iOS              |
  +--------+---------+  +--------+----------+  +--------+---------+
           |                     |                      |
           +---------------------+----------------------+
                                 |
                    WireGuard UDP:41641
                    (NAT keepalive: 25s ping cycle)
                                 |
===============================================================================
                                 v
  HOMELAB HOST (Linux, NVIDIA GPU)
  LAN IP: 192.168.29.133 | Tailscale IP: 100.123.147.108
  TCP Congestion: BBR (stable streaming over high-latency path)
+-----------------------------------------------------------------------------+
|                                                                             |
|  TAILSCALE INTERFACE (tailscale0)                                           |
|  IP: 100.123.147.108 | Port: UDP 41641                                     |
|                                                                             |
|  +-----------------------------------------------------------------------+  |
|  |  UFW FIREWALL (restrict inbound to tailscale0 only)                   |  |
|  |                                                                       |  |
|  |  ALLOW: TCP/UDP 53 on tailscale0  -->  Pi-hole (DNS)                  |  |
|  |  ALLOW: TCP 80    on tailscale0  -->  Nginx Proxy Manager (HTTP)      |  |
|  |  ALLOW: TCP 443   on tailscale0  -->  Nginx Proxy Manager (HTTPS)     |  |
|  |  DENY:  all other inbound                                             |  |
|  +-----------------------------------------------------------------------+  |
|                                 |                                            |
|                                 v                                            |
|  +-----------------------------------------------------------------------+  |
|  |  HOST PORT BINDINGS (bound to 0.0.0.0 to avoid boot race condition)  |  |
|  |                                                                       |  |
|  |  0.0.0.0:53  --> pihole container (DNS)                               |  |
|  |  0.0.0.0:80  --> nginx-proxy-manager container (HTTP)                 |  |
|  |  0.0.0.0:443 --> nginx-proxy-manager container (HTTPS/TLS)            |  |
|  +-----------------------------------------------------------------------+  |
|                                 |                                            |
|                                 v                                            |
|  +-----------------------------------------------------------------------+  |
|  |               DOCKER EXTERNAL NETWORK: "proxy"                        |  |
|  |               (all reverse-proxied services join this network)        |  |
|  |               Docker embedded DNS: 127.0.0.11:53                      |  |
|  |                                                                       |  |
|  |  +---------------------------+    +-------------------------------+   |  |
|  |  |        PI-HOLE            |    |    NGINX PROXY MANAGER        |   |  |
|  |  |  container: pihole        |    |  container: nginx-proxy-mgr   |   |  |
|  |  |  port: 53 (TCP/UDP)       |    |  port: 80 (HTTP), 443 (TLS)  |   |  |
|  |  |                           |    |                               |   |  |
|  |  |  Wildcard DNS rule:       |    |  TLS termination (SNI-based) |   |  |
|  |  |  *.homelab.ansh-info.com  |    |  Let's Encrypt wildcard cert |   |  |
|  |  |  --> 100.123.147.108      |    |  Cloudflare DNS challenge    |   |  |
|  |  +---------------------------+    +-------+-----+---------+-------+   |  |
|  |                                           |     |         |           |  |
|  |              NPM PROXY HOST ROUTING       |     |         |           |  |
|  |              (hostname --> container:port) |     |         |           |  |
|  |  +----------------------------------------+-----+---------+--------+  |  |
|  |  |                                                                 |  |  |
|  |  |  seerr.homelab.ansh-info.com        --> seerr:5055              |  |  |
|  |  |  jellyfin.homelab.ansh-info.com     --> jellyfin:8096           |  |  |
|  |  |  immich.homelab.ansh-info.com       --> immich_server:2283      |  |  |
|  |  |  radarr.homelab.ansh-info.com       --> radarr:7878             |  |  |
|  |  |  sonarr.homelab.ansh-info.com       --> sonarr:8989             |  |  |
|  |  |  prowlarr.homelab.ansh-info.com     --> prowlarr:9696           |  |  |
|  |  |  bazarr.homelab.ansh-info.com       --> bazarr:6767             |  |  |
|  |  |  qbit.homelab.ansh-info.com         --> qbittorrent:8080        |  |  |
|  |  |  homarr.homelab.ansh-info.com       --> homarr:7575             |  |  |
|  |  |  openclaw.homelab.ansh-info.com     --> openclaw-gateway:18789  |  |  |
|  |  |  nextcloud.homelab.ansh-info.com    --> localhost:11000          |  |  |
|  |  |  budget.homelab.ansh-info.com       --> actual-budget:5006      |  |  |
|  |  |  status.homelab.ansh-info.com       --> uptime-kuma:3001        |  |  |
|  |  |  vault.homelab.ansh-info.com        --> vaultwarden:80          |  |  |
|  |  |  portainer.homelab.ansh-info.com    --> portainer:9000          |  |  |
|  |  |  pihole.homelab.ansh-info.com       --> pihole:80               |  |  |
|  |  |                                                                 |  |  |
|  |  +-----------------------------------------------------------------+  |  |
|  |                                                                       |  |
|  |  +-- MEDIA STACK -------+  +-- PHOTO STACK ------+  +-- CLOUD -----+ |  |
|  |  | jellyfin  (GPU/8096) |  | immich_server (2283)|  | nextcloud-aio| |  |
|  |  | radarr        (7878) |  | immich_ml     (ML)  |  | (11000)      | |  |
|  |  | sonarr        (8989) |  | immich_redis        |  +--------------+ |  |
|  |  | prowlarr      (9696) |  | immich_postgres     |                    |  |
|  |  | bazarr        (6767) |  +---------------------+  +-- AI --------+ |  |
|  |  | qbittorrent   (8080) |                           | openclaw     | |  |
|  |  | seerr         (5055) |  +-- UTILITIES ---------+ | (18789)      | |  |
|  |  | homarr        (7575) |  | actual-budget (5006) | +--------------+ |  |
|  |  +-----------------------+  | uptime-kuma  (3001) |                   |  |
|  |                             | vaultwarden  (80)   |  +-- OPS ------+ |  |
|  |                             | portainer    (9000) |  | watchtower  | |  |
|  |                             +---------------------+  | (no port)   | |  |
|  |                                                      +--------------+ |  |
|  +-----------------------------------------------------------------------+  |
|                                                                             |
|  PERSISTENT STORAGE: /mnt/ssd/docker-volumes/                               |
|  +-----------------------------------------------------------------------+  |
|  |  pihole/          nginx-proxy-manager/   arr/                         |  |
|  |  immich/          nextcloud/             openclaw/                     |  |
|  |  actual-budget/   uptime-kuma/           vaultwarden/                  |  |
|  +-----------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------+

===============================================================================
                         DNS RESOLUTION CHAIN
===============================================================================

  Client browser requests: https://seerr.homelab.ansh-info.com
                                     |
                                     v
  1. Tailscale Split DNS (admin console config)
     Domain: homelab.ansh-info.com --> Nameserver: 100.123.147.108
                                     |
                                     v
  2. Pi-hole (UDP/TCP 53)
     dnsmasq rule: address=/.homelab.ansh-info.com/100.123.147.108
     Response: seerr.homelab.ansh-info.com --> 100.123.147.108
                                     |
                                     v
  3. Client connects to 100.123.147.108:443 with SNI hostname
                                     |
                                     v
  4. NPM terminates TLS (wildcard cert: *.homelab.ansh-info.com)
     Matches proxy host --> forwards to seerr:5055 on Docker network
                                     |
                                     v
  5. Seerr responds --> NPM re-encrypts --> Client receives page

===============================================================================
                         EXTERNAL DEPENDENCIES
===============================================================================

  Cloudflare (ansh-info.com)           Tailscale Admin Console
  - Domain registrar                   - Split DNS config
  - DNS challenge for Let's Encrypt    - ACL policies
  - NOT the private DNS authority      - Device management

  Jio Router (192.168.29.1)            NVIDIA GPU (on host)
  - NAT gateway to internet            - Jellyfin HW transcoding
  - Aggressive UDP expiry (30-60s)     - Nextcloud media processing
  - Keepalive service compensates
```

Core platform components:

- `Tailscale` for private network access (WireGuard mesh, Split DNS routing)
- `Pi-hole` for internal DNS authority (wildcard dnsmasq rule)
- `Nginx Proxy Manager` for hostname-based TLS routing (SNI + Let's Encrypt)
- `Docker` plus `Portainer` for stack deployment and operations
- Shared external Docker network `proxy` for all reverse-proxied services
- `UFW` firewall restricting inbound to `tailscale0` interface only
- `BBR` congestion control for stable streaming over high-latency path
- `Systemd keepalive` service preventing NAT expiry on Jio router

## Current Stack Layout

The main service definitions live under [docker-compose](docker-compose):

- [docker-compose/pihole/docker-compose.yml](docker-compose/pihole/docker-compose.yml)
- [docker-compose/nginx-proxy-manager/docker-compose.yml](docker-compose/nginx-proxy-manager/docker-compose.yml)
- [docker-compose/jellyfin-arr-stack/docker-compose.yml](docker-compose/jellyfin-arr-stack/docker-compose.yml)
- [docker-compose/immich/docker-compose.yml](docker-compose/immich/docker-compose.yml)
- [docker-compose/nextcloud-aio/docker-compose.yml](docker-compose/nextcloud-aio/docker-compose.yml)
- [docker-compose/openclaw/docker-compose.yml](docker-compose/openclaw/docker-compose.yml)
- [docker-compose/actual-budget/docker-compose.yml](docker-compose/actual-budget/docker-compose.yml)
- [docker-compose/duplicati/docker-compose.yml](docker-compose/duplicati/docker-compose.yml)
- [docker-compose/uptime-kuma/docker-compose.yml](docker-compose/uptime-kuma/docker-compose.yml)
- [docker-compose/vaultwarden/docker-compose.yml](docker-compose/vaultwarden/docker-compose.yml)
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
- [docs/stacks/actual-budget.md](docs/stacks/actual-budget.md)
- [docs/stacks/duplicati.md](docs/stacks/duplicati.md)
- [docs/stacks/uptime-kuma.md](docs/stacks/uptime-kuma.md)
- [docs/stacks/vaultwarden.md](docs/stacks/vaultwarden.md)
- [docs/stacks/watchtower.md](docs/stacks/watchtower.md)

## Repository Layout

```
homelab/
├── docker-compose/                  # Portainer stack definitions
│   ├── pihole/                      # DNS authority (port 53)
│   ├── nginx-proxy-manager/         # Reverse proxy (ports 80, 443)
│   ├── jellyfin-arr-stack/          # Media: Jellyfin + Radarr/Sonarr/Prowlarr/Bazarr/qBit/Seerr/Homarr
│   ├── immich/                      # Photo management (server + ML + Redis + Postgres)
│   ├── nextcloud-aio/               # Cloud storage (AIO master container)
│   ├── openclaw/                    # AI assistant gateway
│   ├── actual-budget/               # Personal finance
│   ├── uptime-kuma/                 # Service monitoring
│   ├── vaultwarden/                 # Password manager (Bitwarden-compatible)
│   └── watchtower/                  # Automatic container image updates
├── docs/                            # Rebuild and operations documentation
│   ├── SETUP.md                     # Host bootstrap guide
│   ├── NETWORKING.md                # Full networking model and troubleshooting
│   ├── CLOUDFLARE.md                # Domain and certificate management
│   ├── OPERATIONS.md                # Day-two ops, incident playbooks
│   ├── VARIABLES.md                 # Placeholder variables reference
│   └── stacks/                      # Per-stack deployment and recovery guides
├── aerospace/                       # AeroSpace tiling WM config (macOS)
├── nvim/                            # LazyVim-based Neovim config
├── tmux/                            # Tmux configuration
├── kitty/                           # Kitty terminal config
└── zshrc/                           # Zsh config with lazy loading
```

## Operating Model

- Primary deployment workflow: `Portainer stacks`
- Secondary fallback workflow: `docker compose` and direct `docker` CLI commands for inspection and recovery
- Internal DNS pattern: wildcard records under `*.homelab.ansh-info.com`
- Access pattern: Tailscale only, with `53`, `80`, and `443` allowed on `tailscale0`

## Status

- Core private ingress path is working through Tailscale, Pi-hole, and NPM.
- Major services are defined as separate compose stacks for easier redeploy and troubleshooting.
- Documentation is being rewritten to make rebuilds deterministic and repeatable.
