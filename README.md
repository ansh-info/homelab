# homelab

This repository contains the configuration, infrastructure, and service definitions for my personal homelab environment. It is a work in progress and continuously evolving as I explore and build more capabilities into my setup.

## Overview

My homelab is a self-hosted environment running on a local Ubuntu server with Docker Compose, Tailscale, and GPU support. It is designed to be private, fully containerized, and modular. I enjoy the process of designing, maintaining, and improving my homelab – it's a space where I learn, experiment, and optimize everything from media streaming to self-hosted cloud tools.

The environment is intentionally isolated from the public internet, with access provided only through Tailscale and local network routing. All services are managed using Docker Compose, making them easy to reproduce, back up, and extend.

## Structure

- **`media-server/`** – Docker Compose setup for media management (Radarr, Sonarr, Prowlarr, Jellyfin, qBittorrent, Bazarr)
- **`nextcloud/`** – Self-hosted Nextcloud stack with MariaDB, Redis, and Caddy reverse proxy (TLS over Tailscale)
- **`networking/`** – Reverse proxy configuration, Tailscale DNS setup, local overrides, and service routing
- **`monitoring/`** – Planned Grafana + Prometheus stack for resource and uptime monitoring (coming soon)
- **`infra/`** – Scripts, automation utilities, and systemd unit files for service lifecycle management

## Goals

- Fully containerized homelab using Docker Compose with minimal external dependencies
- Secure-by-default with local and Tailscale-only access (no public ports)
- Hardware-accelerated media streaming using NVIDIA GPU
- Personal cloud tools like file sync, calendar, and contacts via Nextcloud
- Unified monitoring and observability
- Maintainable and easy-to-replicate infrastructure

## Requirements

- Docker & Docker Compose
- Tailscale account and client installed
- NVIDIA GPU drivers (for media server acceleration)
- Basic Linux environment (tested on Ubuntu Server)

## Status

- Core services (media server, Nextcloud) are up and running
- Reverse proxy (Caddy with Tailscale TLS) is configured and stable
- Monitoring and automation components are under development
