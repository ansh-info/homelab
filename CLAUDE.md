# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Source of truth for rebuilding and operating a personal homelab. Contains Docker Compose stack definitions, dotfiles (nvim, tmux, kitty, aerospace, zsh), and operational documentation. Not a software project with application code - it is infrastructure-as-config.

## Architecture

Private-first homelab accessed exclusively through Tailscale:

1. Tailscale provides private network connectivity
2. Tailscale Split DNS sends `*.homelab.ansh-info.com` queries to Pi-hole
3. Pi-hole resolves hostnames to the homelab Tailscale IP
4. Nginx Proxy Manager routes traffic to containers on the shared `proxy` Docker network

Primary deployment interface is Portainer. Docker CLI is the fallback for inspection and recovery.

## Validation Commands

```bash
# Validate a specific compose stack (run from its directory)
cd docker-compose/<stack-name> && docker compose config

# Validate all stacks like CI does (needs env vars)
PIHOLE_PASSWORD=placeholder TAILSCALE_IP=127.0.0.1 \
UPLOAD_LOCATION=/tmp/u DB_DATA_LOCATION=/tmp/d \
DB_PASSWORD=x DB_USERNAME=x DB_DATABASE_NAME=x \
OPENCLAW_GATEWAY_TOKEN=x \
docker compose -f docker-compose/<stack>/docker-compose.yml config

# Validate aerospace TOML syntax
python3 -c "import tomllib, pathlib; tomllib.load(pathlib.Path('aerospace/aerospace.toml').open('rb'))"
```

CI runs `docker compose config` for every stack on all pushes. The immich stack requires its `stack.env` file in the same directory.

## Key Conventions

- **Storage paths**: All persistent bind mounts under `/mnt/ssd/docker-volumes/<stack-or-service>/...` - never introduce scattered storage roots
- **Networking**: Reverse-proxied services join the external `proxy` network. Never bind ports to the Tailscale IP directly (boot-time race condition)
- **Formatting**: No em dashes - use short hyphens only
- **Commits**: Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `refactor:`, `perf:`). Semantic release bumps version automatically on main
- **Co-authors**: All commits include co-author trailers for `anshkumar.info@gmail.com` and `apoorvaagupta.info@gmail.com`
- **New stacks**: Place at `docker-compose/<name>/docker-compose.yml`, update README.md, `docs/README.md`, `docs/stacks/`, `docs/VARIABLES.md`, and the CI validation matrix in `.github/workflows/docker-compose-validate.yml`

## Stack Layout

Nine compose stacks under `docker-compose/`:

- `pihole` - DNS authority (port 53 on host)
- `nginx-proxy-manager` - Reverse proxy (ports 80, 443 on host)
- `jellyfin-arr-stack` - Media: Jellyfin (NVIDIA GPU), Radarr, Sonarr, Prowlarr, Bazarr, Homarr, qBittorrent, Seerr
- `immich` - Photo management (uses `stack.env` for config)
- `nextcloud-aio` - Cloud storage (two NPM hosts: admin + app)
- `openclaw` - AI assistant gateway (stateful, manual updates only)
- `actual-budget` - Personal finance and envelope budgeting
- `duplicati` - Encrypted backups of docker-volumes to HDD
- `watchtower` - Auto-updates for other containers

## Dotfiles

- `nvim/` - LazyVim-based Neovim config
- `tmux/.tmux.conf` - Tmux configuration
- `kitty/kitty.conf` - Kitty terminal config
- `aerospace/aerospace.toml` - AeroSpace tiling WM for macOS
- `zshrc/.zshrc` - Zsh config with lazy loading

## Release Process

Python semantic-release runs on main via GitHub Actions. Version tracked in `pyproject.toml`. The `CHANGELOG.md` is auto-generated.

## Verification After Changes

```bash
# Check compose files and docs agree
rg -n 'old-path-or-old-name' docker-compose docs README.md

# End-to-end DNS and proxy check (from tailnet client)
dig +short <service>.homelab.ansh-info.com @<TAILSCALE_IP>
curl -vk --resolve <service>.homelab.ansh-info.com:443:<TAILSCALE_IP> https://<service>.homelab.ansh-info.com/
```

## Notable Exceptions

- Jellyfin requires `runtime: nvidia` and NVIDIA env vars - do not remove
- Pi-hole v6 requires `FTLCONF_misc_etc_dnsmasq_d: "true"` to load `/etc/dnsmasq.d`
- Nextcloud AIO container name `nextcloud-aio-mastercontainer` is immutable
- Immich compose references `stack.env` via `env_file:` (not `.env`)

## Further Context

- `AGENTS.md` - detailed rules for service addition, storage layout, NPM config, and documentation updates
- `docs/NETWORKING.md` - full networking model, Tailscale NAT keepalive fix, and failure diagnostics
- `docs/OPERATIONS.md` - day-two operations, incident playbooks, and backup priorities
