# Private HTTPS with Caddy + Pi-hole (no public IP, no public exposure)

Notes:This is a step-by-step of what we changed and why it worked. It mirrors your Nextcloud pattern: **Caddy on the host terminates HTTPS with `tls internal`**, and **Pi-hole’s web UI is only reachable via localhost**. DNS (53/tcp+udp) remains reachable to your clients; nothing else is exposed publicly.

---

## Final topology (what you end up with)

- **Caddy** (`network_mode: "host"`) listens on 443 and proxies:
  - `https://nextcloud.homelab.ansh.com` → `localhost:11000`
  - `https://pihole.homelab.ansh.com` → `localhost:10081`

- **Pi-hole**
  - **DNS** published on the LAN (and optionally Tailscale) IPs: `:53/tcp`, `:53/udp`
  - **Web UI** bound only to loopback: `127.0.0.1:10081 → container:80`

- **Local DNS records** in Pi-hole map the hostnames to your server IP (LAN or 100.x).

> Result: You can reach both services over private HTTPS. No public IP nor domain purchase required. The UI is **not** directly exposed; only Caddy can reach it.

---

## 1) Put the Caddyfile on disk and bind-mount it (no Docker “configs”)

Create the file on the host:

```bash
sudo mkdir -p /mnt/ssd/caddy
sudo tee /mnt/ssd/caddy/Caddyfile >/dev/null <<'EOF'
https://nextcloud.homelab.ansh.com {
    tls internal
    reverse_proxy localhost:11000
}

https://pihole.homelab.ansh.com {
    tls internal
    # optional: normalize /admin -> /admin/
    @noSlash path /admin
    redir @noSlash /admin/ 308

    reverse_proxy localhost:10081
}
EOF
sudo chmod 644 /mnt/ssd/caddy/Caddyfile
```

**Why:** Docker `configs:` are immutable snapshots inside the container. Your Pi-hole vhost wasn’t loading because the running container still had the **old** snapshot. A bind-mounted file ensures edits take effect immediately after `caddy reload`.

---

## 2) Caddy service (host network; bind-mount the Caddyfile)

```yaml
services:
  caddy:
    image: caddy:alpine
    container_name: caddy
    restart: always
    network_mode: "host"
    volumes:
      - /mnt/ssd/caddy:/etc/caddy:ro # <— directory→directory (includes Caddyfile)
      - caddy_certs:/certs
      - caddy_config:/config
      - caddy_data:/data
      - caddy_sites:/srv
# REMOVE any `configs:` pointing at /etc/caddy/Caddyfile
volumes:
  caddy_certs:
  caddy_config:
  caddy_data:
  caddy_sites:
```

---

## 3) Pi-hole service (DNS exposed; UI private)

```yaml
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      # DNS for LAN clients (adjust IP to your LAN interface)
      - "192.168.29.250:53:53/tcp"
      - "192.168.29.250:53:53/udp"
      # Optional: DNS for Tailscale clients
      # - "<tailscale-ip>:53:53/tcp"
      # - "<tailscale-ip>:53:53/udp"

      # Web UI: loopback-only (Caddy will proxy this)
      - "127.0.0.1:10081:80/tcp"
    environment:
      TZ: "Asia/Kolkata"
      FTLCONF_webserver_api_password: "REDACTED" # move to .env or secret if possible
      FTLCONF_dns_listeningMode: "all"
    volumes:
      - "./etc-pihole:/etc/pihole"
      # - "./etc-dnsmasq.d:/etc/dnsmasq.d"   # only if you actually use it
    cap_add:
      - NET_ADMIN
      - SYS_TIME
      - SYS_NICE
    restart: unless-stopped
```

**Why:** The UI is **not** reachable from the network (only `127.0.0.1`). Caddy (host network) connects to it via `localhost:10081`. DNS remains available to clients on the IPs you publish.

---

## 4) Local DNS records (Pi-hole → Settings → DNS → Local DNS)

Create A-records so your private hostnames resolve to your server IP:

- `nextcloud.homelab.ansh.com` → `<tailscale-ip>` (or your LAN IP)
- `pihole.homelab.ansh.com` → `<tailscale-ip>` (or your LAN IP)

**No** public DNS, no public IP needed.

---

## 5) Deploy & reload sequence

```bash
# start / update pihole
docker compose up -d pihole

# start / update caddy
docker compose up -d caddy

# confirm the file inside the container (should show both vhosts)
docker exec -it caddy sh -lc 'nl -ba /etc/caddy/Caddyfile'

# reload caddy to pick up changes
docker exec caddy caddy fmt --overwrite /etc/caddy/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# logs should mention both hostnames:
docker logs caddy --since=2m | egrep -i 'serving|domains|nextcloud|pihole'
```

Expected lines include:

```
enabling automatic TLS certificate management {"domains":["nextcloud.homelab.ansh.com","pihole.homelab.ansh.com"]}
certificate obtained successfully {"identifier":"pihole.homelab.ansh.com","issuer":"local"}
serving initial configuration
```

---

## 6) Validation tests

```bash
# Upstream UI reachable locally (308/302/200 are fine)
curl -sI http://127.0.0.1:10081/admin | head -n1

# DNS resolves your hostnames
dig +short nextcloud.homelab.ansh.com
dig +short pihole.homelab.ansh.com

# HTTPS through Caddy (expect 2xx/3xx and Caddy headers)
curl -vkI https://nextcloud.homelab.ansh.com
curl -vkI https://pihole.homelab.ansh.com

# Force SNI to your server IP to rule out resolver/path issues
curl -vkI --resolve pihole.homelab.ansh.com:443:<YOUR_SERVER_IP> https://pihole.homelab.ansh.com
```

> With `tls internal`, browsers will warn unless you install Caddy’s root CA on clients. Export it from the container: `/data/caddy/pki/authorities/local/root.crt`.

---

## What was broken (and how we fixed it)

- **Root cause 1 – Stale/competing Caddyfile mapping**
  - You had **both** a Docker `configs:` entry **and** a bind-mount targeting `/etc/caddy/Caddyfile`. The container ended up using the old **config snapshot**, which contained only the Nextcloud site. Result: TLS handshake for `pihole.homelab.ansh.com` failed (SNI unmatched → “TLS alert internal error”).
  - **Fix:** Remove `configs:`; use a **bind-mounted Caddyfile** from `/mnt/ssd/caddy/Caddyfile` and `caddy reload`.

- **Root cause 2 – Upstream UI port mismatch (earlier)**
  - Caddy was pointing to `localhost:80` while the Pi-hole UI wasn’t published there.
  - **Fix:** Publish Pi-hole UI on `127.0.0.1:10081` and point Caddy to `localhost:10081`.

After those changes, logs showed both domains and a successfully obtained **local** certificate for Pi-hole, and `curl` worked.

---

## “No public exposure” notes

- **Only DNS ports** (53/tcp+udp) are published to the LAN/Tailscale IPs you chose.
- The **web UI** is bound to `127.0.0.1` only; not reachable from the network.
- Caddy listens on 443 due to host networking. If your server also has a public interface and you want to be extra strict, use your OS firewall (e.g., `ufw`/`nftables`) to **allow 443 only from LAN/Tailscale subnets**.

---

## Adding more services later

Add another site block and point it to a loopback-published port:

```caddy
https://media.homelab.ansh.com {
    tls internal
    reverse_proxy localhost:12000
}
```

- Publish that service’s UI as `127.0.0.1:12000:PORT` in its compose.
- Add a Local DNS record for `media.homelab.ansh.com` → your server IP.
- `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`

---

## Handy commands

```bash
# validate caddyfile syntax
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# format it nicely
docker exec caddy caddy fmt --overwrite /etc/caddy/Caddyfile

# live reload
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# check that the upstream is alive
curl -sI http://127.0.0.1:10081/admin | head -n1
```

---
