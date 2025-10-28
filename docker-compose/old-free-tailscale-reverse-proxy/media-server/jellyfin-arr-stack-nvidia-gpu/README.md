# ARR Stack Docker Compose Setup

This Docker Compose file sets up a complete **media management and streaming stack** including applications for movies, TV shows, music, books, torrents, metadata, and a media server. All containers use `linuxserver.io` or official images and are configured with persistent volumes on `/mnt/ssd/arr`.

## Services and Access Ports

| Service     | Description                            | Port   | Web UI                                         |
| ----------- | -------------------------------------- | ------ | ---------------------------------------------- |
| Radarr      | Movie download manager                 | `7878` | [http://localhost:7878](http://localhost:7878) |
| Sonarr      | TV show download manager               | `8989` | [http://localhost:8989](http://localhost:8989) |
| Lidarr      | Music download manager                 | `8686` | [http://localhost:8686](http://localhost:8686) |
| Readarr     | Ebook/audiobook manager (develop)      | `8787` | [http://localhost:8787](http://localhost:8787) |
| Bazarr      | Subtitle manager for Sonarr/Radarr     | `6767` | [http://localhost:6767](http://localhost:6767) |
| Prowlarr    | Indexer manager for Sonarr/Radarr/etc. | `9696` | [http://localhost:9696](http://localhost:9696) |
| qBittorrent | Torrent client                         | `8080` | [http://localhost:8080](http://localhost:8080) |
| Homarr      | Dashboard to manage all services       | `7575` | [http://localhost:7575](http://localhost:7575) |
| Jellyfin    | Media server (GPU accelerated)         | `8096` | [http://localhost:8096](http://localhost:8096) |

## Features

- **Persistent Storage**: All configs and media paths are mapped to `/mnt/ssd/arr` to ensure data persists across container restarts.
- **Unified Download Directory**: All apps (Radarr, Sonarr, Lidarr, etc.) share a common download path via `/mnt/ssd/arr/qbittorrent/downloads`.
- **GPU Acceleration**: Jellyfin uses NVIDIA GPU for faster transcoding with `runtime: nvidia`.
- **Service Dashboard**: Homarr provides a customizable landing page to manage all services in one place.
- **TZ, PUID, PGID**: These environment variables ensure consistent timezone and proper file permissions (user ID 1000).

## Before You Start

- Ensure NVIDIA Docker runtime is installed for Jellyfin to use GPU.
- Create the directory structure under `/mnt/ssd/arr/` as specified in the volume mappings.
- Adjust `PUID`, `PGID`, and `TZ` as needed for your system.

## Deployment

Run the stack:

```bash
docker-compose up -d
```

Stop the stack:

```bash
docker-compose down
```

## Recommended Use

- Configure indexers in **Prowlarr**, then link them to **Sonarr, Radarr, Lidarr, Readarr**.
- Manage and monitor torrent downloads via **qBittorrent**.
- Automatically download subtitles using **Bazarr**.
- Stream content using **Jellyfin**.
- Use **Homarr** as a central hub to quickly access all applications.
