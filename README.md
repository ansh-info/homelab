# homelab

This repository contains the configuration, infrastructure, and service definitions for my personal homelab environment. It is a work in progress and continuously evolving.

## Structure

- **`media-server/`** – Docker Compose setup for media management (Radarr, Sonarr, Prowlarr, Jellyfin, etc.)
- **`networking/`** – Reverse proxy configs, Tailscale setup, DNS overrides, and internal routing (WIP)
- **`monitoring/`** – Planned Grafana + Prometheus stack (upcoming)
- **`infra/`** – Scripts, systemd units, and automation tools for service lifecycle (WIP)

## Goals

- Fully containerized homelab using Docker Compose and minimal dependencies
- Local-only or Tailscale-accessible services (zero public exposure)
- Hardware-accelerated media streaming
- Unified dashboard and monitoring

## Requirements

- Docker & Docker Compose
- NVIDIA GPU drivers (for acceleration)
- Basic Linux environment (tested on Ubuntu Server)

## Status

- Core services are up and running (`media-server/`)
- Infrastructure and monitoring components are under development
