# Immich Homelab Setup (Docker + Portainer + Caddy + Pi-hole + Tailscale) — **No Public Exposure**

This guide walks you through installing **Immich** using **Portainer** and **Docker Compose**, storing data on an SSD, binding the UI to **loopback only** for security, fronting it with **Caddy** (TLS via Caddy’s internal CA), resolving a friendly hostname via **Pi-hole**, and reaching it remotely over **Tailscale** — all **without exposing any public IP/ports**.

---

## What you’ll build

- **Immich** (photos/videos) running in Docker with:
  - Data at: `/mnt/ssd/immich/{library,postgres,model-cache}`
  - **Loopback-only** bind: `127.0.0.1:2283` (not reachable directly from LAN/Internet)

- **Caddy** reverse proxy:
  - Site: `https://immich.homelab.ansh.com`
  - `tls internal` (Caddy’s local CA), proxied to `127.0.0.1:2283`

- **Pi-hole**: local DNS A record `immich.homelab.ansh.com → <server LAN IP>`
- **Tailscale**: remote access to the same internal hostname **without** any public port forwards

> **Security model:** Nothing is published to the Internet. Immich only listens on loopback; LAN clients reach it via Caddy on your server’s LAN IP. Remote devices use Tailscale to reach your LAN and resolve the same hostname via Pi-hole.

---

## Prerequisites

- Host with **Docker Engine** and **Portainer** (Stacks enabled)
- **Caddy** installed on the same host as Immich
- **Pi-hole** admin access (local DNS)
- **Tailscale** on your server and remote devices
- SSD mounted at `/mnt/ssd` (or adjust paths accordingly)

---

## 1) Prepare directories (host)

```bash
sudo mkdir -p /mnt/ssd/immich/{library,postgres,model-cache}
sudo chown -R $USER:$USER /mnt/ssd/immich
# If Postgres later complains about perms:
# sudo chown -R 999:999 /mnt/ssd/immich/postgres
```

- `library/` → Immich photo/video storage
- `postgres/` → database (do **not** place on a network share)
- `model-cache/` → AI model cache (faster restarts)

---

## 2) Create your **stack.env** (Portainer will load this)

In Portainer → **Stacks** → (new or existing Immich stack) → **Add file** named `stack.env`:

```
UPLOAD_LOCATION=/mnt/ssd/immich/library
DB_DATA_LOCATION=/mnt/ssd/immich/postgres
TZ=Asia/Kolkata
IMMICH_VERSION=release
DB_USERNAME=postgres
DB_PASSWORD=ChangeMe12345
DB_DATABASE_NAME=immich
```

> Per Immich docs, keep `DB_PASSWORD` alphanumeric (`A–Z a–z 0–9`).

---

## 3) Use this **docker-compose.yml** in your Portainer stack

Paste this in the stack editor (same folder as `stack.env`):

```yaml
name: immich

services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    volumes:
      - ${UPLOAD_LOCATION}:/data
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - stack.env
    ports:
      - "127.0.0.1:2283:2283" # loopback-only; NOT reachable from LAN/Internet
    depends_on:
      - redis
      - database
    restart: always
    healthcheck:
      disable: false

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
    volumes:
      - /mnt/ssd/immich/model-cache:/cache
    env_file:
      - stack.env
    restart: always
    healthcheck:
      disable: false

  redis:
    container_name: immich_redis
    image: docker.io/valkey/valkey:8-bookworm@sha256:fea8b3e67b15729d4bb70589eb03367bab9ad1ee89c876f54327fc7c6e618571
    healthcheck:
      test: redis-cli ping || exit 1
    restart: always

  database:
    container_name: immich_postgres
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:c44be5f2871c59362966d71eab4268170eb6f5653c0e6170184e72b38ffdf107
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
      POSTGRES_INITDB_ARGS: "--data-checksums"
      # DB_STORAGE_TYPE: 'HDD'   # uncomment if DB is on spinning disk
    volumes:
      - ${DB_DATA_LOCATION}:/var/lib/postgresql/data
    shm_size: 128mb
    restart: always
```

Click **Deploy/Update the Stack**.

**Health check:** In Portainer → Stacks → your stack → containers should be **healthy/running**.

---

## 4) Configure **Caddy** (reverse proxy with internal TLS)

Add this site block to your **Caddyfile** and reload Caddy:

```caddyfile
immich.homelab.ansh.com {
    tls internal
    reverse_proxy 127.0.0.1:2283
    encode zstd gzip
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
}
```

Reload:

```bash
sudo systemctl reload caddy
# or: sudo caddy reload --config /etc/caddy/Caddyfile
```

> `tls internal` uses Caddy’s private CA. To avoid warnings on clients, install the root CA:
>
> - On server: `sudo caddy trust`
> - On other devices: import `/var/lib/caddy/pki/authorities/local/root.crt`

---

## 5) Add **Pi-hole** DNS

In Pi-hole admin → **Local DNS Records**:

- **Domain:** `immich.homelab.ansh.com`
- **IP:** `<server LAN IP>` (e.g., `192.168.29.250`)

Now LAN devices resolve the hostname to your server, and Caddy proxies to loopback.

---

## 6) First-run Immich setup

Open **[https://immich.homelab.ansh.com](https://immich.homelab.ansh.com)** from a LAN client:

- Create admin user
- **Admin → Settings → Server → External domain**: set to `https://immich.homelab.ansh.com`
- Install Immich mobile app (iOS/Android) → log in → enable **Auto Backup**

---

## 7) Tailscale: remote access (still no public exposure)

You have two common options to keep the same hostname working remotely:

**Option A — Use Pi-hole as Tailscale DNS**

1. In **Tailscale Admin** → **DNS** → **Nameservers**, add your **Pi-hole LAN IP**.
2. (Optional) **Split DNS** for `homelab.ansh.com` so lookups always go to Pi-hole.
3. Ensure your server is reachable via Tailscale (subnet router or direct node).

**Option B — Use Tailscale on clients and access via LAN name**

- If your client routes to your LAN over Tailscale (subnet routing), it can use Pi-hole and resolve `immich.homelab.ansh.com` as if on LAN.

> In both cases, you **do not** open any public ports. Tailscale builds the secure overlay; Pi-hole serves DNS; Caddy serves HTTPS internally.

---

## 8) Verification checklist

- **Docker**

  ```bash
  docker ps
  # expect: immich_server, immich_machine_learning, immich_postgres, immich_redis
  ```

- **Immich bound only on loopback**

  ```bash
  ss -tulpn | grep 2283
  # should show 127.0.0.1:2283 (not 0.0.0.0)
  ```

- **Caddy serving your site**

  ```bash
  curl -I https://immich.homelab.ansh.com
  # expect HTTP/2 200 (or 302 on first hit)
  ```

- **LAN DNS**
  From a LAN client:

  ```bash
  nslookup immich.homelab.ansh.com
  # returns your server's LAN IP
  ```

- **Tailscale**
  From a remote device on Tailscale:

  ```bash
  nslookup immich.homelab.ansh.com
  # returns the same LAN IP via Pi-hole
  ```

---

## 9) Backup suggestions (optional but recommended)

- **Restic**/Duplicati to back up:
  - `/mnt/ssd/immich/library` (media)
  - `/mnt/ssd/immich/postgres` (DB)

- Store backups to a second disk, NAS, S3/Backblaze, or your Nextcloud backup area.
- Snapshot-friendly FS (e.g., btrfs/zfs) is a plus for quick rollbacks.

---

## 10) Troubleshooting

- **Port mismatch:** Caddy must point to the **same** port you expose: `reverse_proxy 127.0.0.1:2283`.
- **Permissions (Postgres):**
  If logs show permission errors:

  ```bash
  sudo chown -R 999:999 /mnt/ssd/immich/postgres
  ```

- **Healthcheck warning on older Docker:**
  If you see `healthcheck.start_interval requires Docker v25+`, you can comment out the `start_interval` line in a future compose if present (your current file disables only).
- **Certificate trust:**
  Import Caddy’s root CA on clients to eliminate HTTPS warnings when using `tls internal`.
- **WAN exposure check:**
  Verify your router has **no port forwards** for 2283 or 443 to this host.

---

## 11) What you achieved

- Immich running from Portainer with persistent storage on SSD
- UI **not** directly reachable (loopback-only)
- Clean HTTPS fronted by Caddy with internal CA
- Friendly hostname via Pi-hole, works on LAN and over Tailscale
- **Zero public IP exposure** 🎉

---
