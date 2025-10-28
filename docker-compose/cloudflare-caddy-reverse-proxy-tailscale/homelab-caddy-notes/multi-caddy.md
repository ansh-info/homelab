Notes: Absolutely — you can put **qBittorrent** (and the rest of your \*arr stack) behind the **same Caddy** you already run. Two key rules to keep it private and clean:

1. **Bind each app to localhost on the host** so they’re **not** reachable directly on the LAN.
2. Give each app its **own hostname** in Caddy with `tls internal` (your internal CA) and **(optionally)** `bind <tailscale-ip>` so it’s reachable **only over Tailscale**.

Below I’ll show (A) the minimal changes to your \*arr compose, (B) the Caddyfile you can paste, and (C) the Pi-hole DNS entries to add.

---

# A) Lock apps to localhost (arr stack changes)

Change each `ports:` mapping so the **host side** is `127.0.0.1:<port>`.
(Leave qBittorrent’s **torrent port** behavior as-is; see note below.)

```yaml
services:
  radarr:
    ...
    ports:
      - 127.0.0.1:7878:7878

  sonarr:
    ...
    ports:
      - 127.0.0.1:8989:8989

  prowlarr:
    ...
    ports:
      - 127.0.0.1:9696:9696

  bazarr:
    ...
    ports:
      - 127.0.0.1:6767:6767

  lidarr:
    ...
    ports:
      - 127.0.0.1:8686:8686

  readarr:
    ...
    ports:
      - 127.0.0.1:8787:8787

  homarr:
    ...
    ports:
      - 127.0.0.1:7575:7575

  qbittorrent:
    ...
    environment:
      - WEBUI_PORT=8080
      - TORRENTING_PORT=6881
    ports:
      # Web UI (private, localhost only)
      - 127.0.0.1:8080:8080
      # Torrenting port(s) – see NOTE below
      - 6881:6881
      - 6881:6881/udp

  jellyfin:
    ...
    ports:
      # HTTP UI only; we'll reverse-proxy this
      - 127.0.0.1:8096:8096
      # You can usually REMOVE 8920 (Jellyfin's own HTTPS) if Caddy does TLS
      # Keep DLNA/mDNS (7359/udp) only if you need LAN device discovery
      - 7359:7359/udp
```

> **NOTE on qBittorrent’s 6881 port:**
> You’re **not exposing** any web UI publicly; it’s on 127.0.0.1 only.
> The 6881 TCP/UDP **peer** port is **not** the same as “public exposure of your web UI”. It’s for torrent peers from the Internet. If you **don’t** port-forward 6881 on your home router, outside peers can’t initiate to you (downloads still work but seeding/connectivity can be reduced). If you ever do want good seeding, you’d need to forward 6881 on the router; this doesn’t expose the web UI.

Apply:

```bash
docker compose up -d
```

---

# B) Add hostnames in your **Caddyfile**

You can keep Caddy in its **own** compose (as you have). Update the Caddyfile content to add one site per app. Use `tls internal` per your preference, and **optionally** add `bind <tailscale-ip>` to force **tailnet-only** access.

```caddyfile
# Keep your Nextcloud site
nextcloud.homelab.ansh.com {
  # bind <tailscale-ip>   # (optional) tailnet-only
  tls internal
  reverse_proxy 127.0.0.1:11000
}

# qBittorrent (Web UI)
qb.homelab.ansh.com {
  # bind <tailscale-ip>
  tls internal
  reverse_proxy 127.0.0.1:8080
}

# Radarr
radarr.homelab.ansh.com {
  # bind <tailscale-ip>
  tls internal
  reverse_proxy 127.0.0.1:7878
}

# Sonarr
sonarr.homelab.ansh.com {
  # bind <tailscale-ip>
  tls internal
  reverse_proxy 127.0.0.1:8989
}

# Prowlarr
prowlarr.homelab.ansh.com {
  # bind <tailscale-ip>
  tls internal
  reverse_proxy 127.0.0.1:9696
}

# Bazarr
bazarr.homelab.ansh.com {
  # bind <tailscale-ip>
  tls internal
  reverse_proxy 127.0.0.1:6767
}

# Lidarr
lidarr.homelab.ansh.com {
  # bind <tailscale-ip>
  tls internal
  reverse_proxy 127.0.0.1:8686
}

# Readarr
readarr.homelab.ansh.com {
  # bind <tailscale-ip>
  tls internal
  reverse_proxy 127.0.0.1:8787
}

# Homarr
home.homelab.ansh.com {
  # bind <tailscale-ip>
  tls internal
  reverse_proxy 127.0.0.1:7575
}

# Jellyfin
jellyfin.homelab.ansh.com {
  # bind <tailscale-ip>
  tls internal
  reverse_proxy 127.0.0.1:8096
}
```

Reload Caddy:

```bash
docker exec -it caddy caddy reload --config /etc/caddy/Caddyfile
```

> Caddy handles WebSockets automatically, so Jellyfin streaming and the \*arr UIs work out of the box.
> If you want **tailnet-only** enforcement at the firewall too, add UFW rules allowing 80/443 only on `tailscale0` (you’ve seen this earlier).

---

# C) Add Pi-hole DNS records (Split DNS still on)

In **Pi-hole → Local DNS → DNS Records**, add A records pointing to your **Tailscale IP** (example `<tailscale-ip>`):

```
qb.homelab.ansh.com       <tailscale-ip>
radarr.homelab.ansh.com   <tailscale-ip>
sonarr.homelab.ansh.com   <tailscale-ip>
prowlarr.homelab.ansh.com <tailscale-ip>
bazarr.homelab.ansh.com   <tailscale-ip>
lidarr.homelab.ansh.com   <tailscale-ip>
readarr.homelab.ansh.com  <tailscale-ip>
home.homelab.ansh.com     <tailscale-ip>
jellyfin.homelab.ansh.com <tailscale-ip>
```

You already enabled **Tailscale DNS → Split DNS** for `homelab.ansh.com` to your Pi-hole over Tailnet, so your Mac/phone will resolve these names privately.

---

## Quick tests

On your Mac (connected to Tailscale):

```bash
dig qb.homelab.ansh.com +short
# expect <tailscale-ip>

curl -I https://qb.homelab.ansh.com --insecure
# should return 200/302 from qBittorrent UI

open https://radarr.homelab.ansh.com
open https://jellyfin.homelab.ansh.com
```

If you installed Caddy’s root CA on the device, you’ll get a green padlock.

---

## App-specific tips (nice to do)

- **qBittorrent**
  - Ensure the Web UI has a strong password.
  - In `Advanced` settings, keep **Host header validation** enabled (default) to protect against DNS rebinding.
  - If you ever get CSRF errors, set **SameSite** cookie to `Lax` or `Strict` in qB’s Web UI settings.

- **Radarr/Sonarr/…**
  - No need to enable SSL in the apps; Caddy provides HTTPS.
  - Leave **URL Base** empty unless you want subpaths (we’re using dedicated hostnames, so not needed).

- **Jellyfin**
  - In Jellyfin admin → **Networking**, add `127.0.0.1` to **Known proxies** so it trusts X-Forwarded headers from Caddy (optional but recommended).
  - If you removed 8920, Jellyfin’s own HTTPS is off; that’s fine since Caddy handles TLS.

---

## TL;DR

- Yes, add qBittorrent (and the rest) to the **same Caddy** by writing **one site block per app**.
- Lock each app’s host port to **127.0.0.1** so only Caddy can reach it.
- Add **Pi-hole A records** for each hostname → Tailscale IP.
- Reload Caddy and enjoy **private HTTPS** for all your services.
