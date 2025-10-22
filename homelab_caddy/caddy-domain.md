# Homelab HTTPS over Tailscale with Caddy + Cloudflare (no public IP exposure)

## TL;DR

- You bought a domain at Cloudflare and **pointed subdomains to your Tailscale IP** (e.g., `<tailscale-ip>`).
- **Caddy** issues **public, browser-trusted certs** via **Let’s Encrypt** using the **DNS-01 challenge** through Cloudflare’s API—so **no inbound ports** need to be reachable from the public internet.
- Clients must be on your **Tailscale tailnet** to reach `*.homelab.<your-domain>`. The 100.x Tailscale IP range is **non-routable on the public internet**, so your services are **not exposed** publicly, yet serve **valid HTTPS** to your devices.

---

## Architecture

```
┌──────────────────────┐      WireGuard (Tailscale)       ┌────────────────────────┐
│  Your device(s)      │  ─────────────────────────────▶  │  Ubuntu host (tailnet) │
│  (Tailscale client)  │                                   │  Tailscale IP: 100.x   │
└─────────▲────────────┘                                   │  Caddy (host network)  │
          │  HTTPS (LE certs, SNI)                        │  Docker services       │
          │                                               └──────────┬─────────────┘
          │                                                           │ reverse_proxy
          │                                                           ▼
          │                                            ┌─────────────────────────────┐
          │                                            │  Radarr / Sonarr / Jellyfin│
          │                                            │  Nextcloud / Portainer ... │
          │                                            └─────────────────────────────┘

              Cloudflare DNS (zone: <your-domain>)
  A records: *.homelab.<your-domain>  →  <tailscale-ip> (DNS-only, not proxied)
```

**Why this is “no-expose”:**

- **Routing**: DNS returns your **Tailscale IP (100.x)**. Only devices on your tailnet can reach 100.x; the public internet cannot.
- **Certificates**: Let’s Encrypt uses **DNS-01** (proves domain control via a TXT record) and **doesn’t connect to your server**, so you don’t need to open ports to the public internet.
- **Firewall**: Even if your host has a public interface, traffic for your `*.homelab.<your-domain>` names goes to 100.x, not any public IP.

---

## Prerequisites

- Cloudflare-managed domain: **<your-domain>**
- Your server is on **Tailscale** (IP like `<tailscale-ip>`)
- Docker + Docker Compose
- (Optional but recommended) Pi-hole for local DNS on your LAN

---

## Step 1 — Cloudflare DNS

Create **A records** (DNS-only, gray cloud) for each service:

| Name                               | Type | Value             | Proxy    |
| ---------------------------------- | ---- | ----------------- | -------- |
| `pihole.homelab.<your-domain>`     | A    | `<tailscale-ip>` | DNS only |
| `nextcloud.homelab.<your-domain>`  | A    | `<tailscale-ip>` | DNS only |
| `portainer.homelab.<your-domain>`  | A    | `<tailscale-ip>` | DNS only |
| … others (radarr/sonarr/jellyfin…) | A    | `<tailscale-ip>` | DNS only |

> **Do not** enable Cloudflare proxy (orange cloud). Cloudflare cannot proxy to 100.x addresses; leave them **DNS-only**.

---

## Step 2 — Cloudflare API Token (for DNS-01)

Create a **restricted API token**:

- **Permissions**:
  - Zone → Zone → Read
  - Zone → DNS → Edit

- **Zone resources**: _Include_ → your zone **<your-domain>** (not “All zones”)
- Save the token as an environment variable for the Caddy container:
  `CLOUDFLARE_API_TOKEN=…`

---

## Step 3 — Caddy container (with Cloudflare DNS module)

Use a Caddy image that includes the Cloudflare DNS plugin (e.g., `ghcr.io/caddybuilds/caddy-cloudflare:latest`).

**Compose snippet (example):**

```yaml
services:
  caddy:
    image: ghcr.io/caddybuilds/caddy-cloudflare:latest
    container_name: caddy
    restart: unless-stopped
    network_mode: "host" # Caddy listens on host :80/:443 (no NAT)
    environment:
      - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
    volumes:
      - caddy_data:/data
      - caddy_config:/config
      - /mnt/ssd/caddy/Caddyfile:/etc/caddy/Caddyfile:ro

volumes:
  caddy_data:
  caddy_config:
```

> **Persistence matters**: `/data` stores ACME accounts and certs. Back it up so you don’t hit Let’s Encrypt rate limits after rebuilds.

---

## Step 4 — Caddyfile (global DNS-01 + site blocks)

**Key rules:**

- Put the **global** block at the top
- **Do not** use `tls internal` (that issues untrusted, internal certs)
- Use straight `https://host { reverse_proxy … }` blocks; Caddy will get Let’s Encrypt certs via DNS-01 for each host when first requested
- For **Portainer**, proxy **HTTPS upstream** and skip verification (self-signed backend)

**Example Caddyfile:**

```caddyfile
{
  email anshkumar.info@gmail.com
  acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}

  # Optional: bind only to Tailscale interface for extra safety
  # servers {
  #   bind <tailscale-ip>
  # }
}

# Pi-hole
https://pihole.homelab.<your-domain> {
  reverse_proxy localhost:10081
}

# Nextcloud (+ DAV well-knowns)
https://nextcloud.homelab.<your-domain> {
  @caldav  path /.well-known/caldav
  @carddav path /.well-known/carddav
  redir @caldav  /remote.php/dav 301
  redir @carddav /remote.php/dav 301

  reverse_proxy localhost:11000
}

# Immich
https://immich.homelab.<your-domain> {
  reverse_proxy localhost:12283
}

# --- ARR apps ---
https://radarr.homelab.<your-domain>     { reverse_proxy localhost:17878 }
https://sonarr.homelab.<your-domain>     { reverse_proxy localhost:18989 }
https://prowlarr.homelab.<your-domain>   { reverse_proxy localhost:19696 }
https://bazarr.homelab.<your-domain>     { reverse_proxy localhost:16767 }
https://lidarr.homelab.<your-domain>     { reverse_proxy localhost:18686 }
https://readarr.homelab.<your-domain>    { reverse_proxy localhost:18787 }
https://homarr.homelab.<your-domain>     { reverse_proxy localhost:17575 }
https://qbittorrent.homelab.<your-domain> { reverse_proxy localhost:18080 }

# Jellyfin (WS auto-handled by Caddy)
https://jellyfin.homelab.<your-domain> {
  header {
    X-Frame-Options "SAMEORIGIN"
  }
  reverse_proxy localhost:18096
}

# Portainer (HTTPS backend on host :19443, self-signed)
https://portainer.homelab.<your-domain> {
  reverse_proxy https://localhost:19443 {
    transport http {
      tls_insecure_skip_verify
      # tls_server_name localhost   # optional: set SNI if needed
    }
  }
}
```

**Validate before restart:**

```bash
docker exec -it caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker restart caddy
```

---

## Step 5 — Pi-hole / Local DNS (so LAN clients resolve your new names)

- Either **forward** queries to public resolvers (Cloudflare 1.1.1.1) and rely on Cloudflare DNS entirely,
- **Or** add **Local DNS Records** in Pi-hole for each `*.homelab.<your-domain>` name → `<tailscale-ip>`, then:

  ```bash
  pihole restartdns
  ```

- Flush DNS cache on clients:
  - Linux: `sudo resolvectl flush-caches` (or `sudo systemd-resolve --flush-caches`)
  - macOS: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
  - Windows (admin): `ipconfig /flushdns`

**Verify:**

```bash
dig +short portainer.homelab.<your-domain>
# expect <tailscale-ip>
```

---

## Step 6 — App-specific touches

### Nextcloud (stop old-domain redirects)

Edit `config/config.php` in Nextcloud’s volume:

```php
'trusted_domains'   => ['nextcloud.homelab.<your-domain>'],
'trusted_proxies'   => ['127.0.0.1', '::1'],
'overwritehost'     => 'nextcloud.homelab.<your-domain>',
'overwriteprotocol' => 'https',
```

Restart the Nextcloud container.

### Portainer

You already confirmed it’s published as `HOST:19443 → CONTAINER:9443`. Keep the Caddy upstream on `https://localhost:19443` with `tls_insecure_skip_verify`.

---

## How certificates work here (why browsers trust it)

- **Caddy** manages **Let’s Encrypt** certificates automatically.
- Because you set `acme_dns cloudflare …`, Caddy uses **DNS-01** (places a TXT record in DNS via Cloudflare’s API).
- Let’s Encrypt validates DNS ownership and issues certs **without** touching your server’s network.
- Result: Your browsers see a **valid, public chain**—no warnings.

**Why you saw warnings earlier:** `tls internal` told Caddy to use its **internal CA** (great for local dev, not trusted by browsers). Removing `tls internal` fixed it.

---

## Ongoing maintenance

- **Backups**: Back up `caddy_data` and `caddy_config` volumes. They contain ACME accounts, certs, and autosave configs.
- **Renewals**: LE certs are 90 days. Caddy auto-renews. You’ll see logs like “got renewal info… certificate obtained successfully”.
- **Logs**:

  ```bash
  docker logs -f caddy | egrep "obtaining certificate|challenge|authz_status|certificate obtained|reverse_proxy"
  ```

- **Format Caddyfile** (handy for readability):

  ```bash
  docker exec -it caddy caddy fmt --overwrite /etc/caddy/Caddyfile
  ```

---

## Optional hardening

- **Bind Caddy to the Tailscale interface only** (avoid binding on all host interfaces):

  ```caddyfile
  {
    servers {
      bind <tailscale-ip>
    }
  }
  ```

- **Tailscale ACLs**: Lock down which users/devices can reach which hosts/ports.
- **Cloudflare token scope**: Keep it limited to the single zone and exact permissions (DNS Edit + Zone Read).
- **Auth / IP allowlists**: For sensitive apps (e.g., Portainer), you can add HTTP Basic Auth or IP allowlists in Caddy as a second layer (beyond Tailscale).

---

## Troubleshooting quick hits

- **Browser warns “site may steal your info”** → you’re using `tls internal` somewhere or hitting the wrong hostname. Remove `tls internal`, ensure you visit `*.<your-domain>` domains, and that DNS resolves correctly.
- **Caddy “crashes” after editing file** → usually a config error. Always run:

  ```bash
  docker exec -it caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
  ```

  before restarting.

- **A host won’t resolve on LAN** → Pi-hole missing record/cached old value. Add local record or forwarders; restart DNS and flush client cache.
- **Cert issuance fails for one site** → confirm the **exact hostname exists in Cloudflare DNS** and is **DNS-only**; check logs for ACME messages.

---

## What you achieved

- **No public IP exposure**: endpoints live on Tailscale (100.x) only.
- **First-class HTTPS**: real, publicly trusted certs via Let’s Encrypt.
- **Unified entrypoint**: Caddy reverse-proxies to all your Docker services.
- **Simple management**: add a site block + DNS record, hit the host once, done.
