# homelab

This repository is the central source of truth for my personal **homelab** setup. It's a continuously evolving, self-hosted infrastructure built for development, experimentation, and automation. While it's currently focused on supporting my **art and media stack**, it is growing into a more complete platform that will power other projects—such as my **Geckos GitHub**, creative tools, and self-hosted developer workflows.

## What This Repo Is

A modular, containerized system that defines everything I run on my local network or via Tailscale. It includes configurations, infrastructure-as-code, dotfiles, and setup scripts to deploy, maintain, and monitor a secure and efficient homelab.

---

## Current Focus Areas

- **Creative stack**: High-performance media management and self-hosted cloud tools tailored for creative workflows
- **Private-first**: No public ports—everything is routed via **Tailscale** or the local LAN
- **GPU acceleration**: Enabled for heavy workloads like media transcoding
- **Art & dev fusion**: Bridging my art stack with local dev services and upcoming tools for my other projects

---

## Repository Structure

| Folder          | Description                                                                   |
| --------------- | ----------------------------------------------------------------------------- |
| `media-server/` | Jellyfin, Radarr, Sonarr, Prowlarr, qBittorrent, Bazarr — all GPU-accelerated |
| `nextcloud/`    | Full Nextcloud stack with MariaDB, Redis, and TLS reverse proxy               |
| `networking/`   | Caddy config, Tailscale DNS, local overrides                                  |
| `monitoring/`   | Grafana + Prometheus stack (in progress)                                      |
| `infra/`        | System scripts, automation, and service unit files                            |

---

## Goals

- **Self-hosted everything**: From media to calendars to developer dashboards
- **Modular design**: Easy to reproduce, rebuild, or migrate
- **Secure by design**: Tailscale as a zero-trust access layer
- **GPU support**: Offload media tasks with NVIDIA acceleration
- **Observable**: Integrated monitoring with Prometheus and Grafana (coming soon)

---

## Requirements

- Docker & Docker Compose
- Tailscale (installed & authenticated)
- NVIDIA GPU with correct drivers
- Ubuntu Server or any recent Linux distro

---

## Coming Soon

- Live metrics via Grafana dashboards
- Local LLM tools for creative + coding workflows
- Automated backups and sync to cloud or external storage

---

## Status

- ✅ Core stack is deployed and stable (media server, Nextcloud, Caddy)
- 🔒 Tailscale DNS + TLS working as expected
- 📈 Monitoring & observability under active development
- 🔧 Future integrations and services are planned as part of the broader platform

---

## Philosophy

This isn't just a homelab—it's a **living lab** where I build systems for myself first. Whether for creativity, development, or learning, everything here is designed to be private, performant, and personally empowering.

---

## License

MIT License
