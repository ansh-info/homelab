# Private Nextcloud over Tailscale + Pi-hole + Caddy (no public exposure)

A step-by-step, **very detailed** guide to reproduce everything we did up to now.
**Goal:** Run Nextcloud privately (no public domain, no port-forwarding), reachable only to your Tailscale devices, with DNS handled by Pi-hole and HTTPS handled by Caddy’s internal CA.

---

## 0) Assumptions & Names you’ll see below

- **Server (Ubuntu) LAN IP (static):** `192.168.29.250`
- **Server Tailscale IP (example):** `<tailscale-ip>`
- **Private hostname:** `nextcloud.homelab.ansh.com`
- **All traffic private:** No public DNS, no router port-forwarding. Access only via Tailscale.
- **Docker & docker compose installed** on the server.

---

# Part A — Give the server a stable LAN IP (Netplan)

### A1) Identify gateway & interface

```bash
ip route | grep default
# expect: default via 192.168.29.1 dev enp42s0 ...

ip a show enp42s0
# confirms current IP & interface name
```

### A2) Create a static config (with modern syntax)

```bash
sudo nano /etc/netplan/10-static-enp42s0.yaml
```

Paste:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp42s0:
      dhcp4: no
      dhcp6: yes
      addresses:
        - 192.168.29.250/24
      routes:
        - to: default
          via: 192.168.29.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

Lock down permissions (Netplan requires root-only):

```bash
sudo chmod 600 /etc/netplan/10-static-enp42s0.yaml
```

### A3) Apply safely

```bash
sudo netplan try
# press ENTER to confirm if SSH stays connected
```

If `try` isn’t available:

```bash
sudo netplan apply
```

### A4) Remove leftover DHCP address (if you still see a second IPv4)

It’s common to have a cloud-init file enabling DHCP. Check:

```bash
ls -1 /etc/netplan
sudo grep -Rni 'enp42s0\|dhcp4' /etc/netplan
```

If you see `50-cloud-init.yaml` with `dhcp4: true`, override it with a higher-priority file:

```bash
printf '%s\n' "network:
  version: 2
  ethernets:
    enp42s0:
      dhcp4: no" | sudo tee /etc/netplan/99-disable-dhcp-enp42s0.yaml
sudo chmod 600 /etc/netplan/99-disable-dhcp-enp42s0.yaml
sudo netplan apply
```

If the old DHCP address persists once, drop it and restart networkd:

```bash
sudo ip addr del 192.168.29.133/24 dev enp42s0 || true
sudo systemctl restart systemd-networkd
ip a show enp42s0   # should now show only 192.168.29.250
```

**Outcome:** Server always comes up as `192.168.29.250` on the LAN.

---

# Part B — Run Pi-hole (DNS only, no DHCP), avoiding port conflicts

### B1) Check who owns port 53

```bash
sudo ss -lunpt | grep ':53'
# typically shows systemd-resolved on 127.0.0.53
```

### B2) Compose service for Pi-hole (binds to specific IPs, UI not on 80/443)

- Keep **Caddy** free to own ports **80/443** later.
- Bind DNS and UI to **specific addresses** to avoid conflicts.

`docker-compose.pihole.yaml` (service snippet):

```yaml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    environment:
      TZ: "Asia/Kolkata"
      FTLCONF_webserver_api_password: "set-a-strong-password"
      FTLCONF_dns_listeningMode: "all"
    # DNS on LAN + (optionally) Tailscale; UI on :8081
    ports:
      - "192.168.29.250:53:53/tcp"
      - "192.168.29.250:53:53/udp"
      # If you want Tailscale clients to use Pi-hole DNS remotely:
      - "<tailscale-ip>:53:53/tcp"
      - "<tailscale-ip>:53:53/udp"
      # Admin UI (bind on both if you want to access via LAN or Tailnet)
      - "192.168.29.250:8081:80/tcp"
      - "<tailscale-ip>:8081:80/tcp"
    volumes:
      - ./pihole/etc-pihole:/etc/pihole
    cap_add:
      - NET_ADMIN
      - SYS_TIME
      - SYS_NICE
```

Start it:

```bash
docker compose -f docker-compose.pihole.yaml up -d
```

### B3) Verify

```bash
sudo ss -ltnp | grep ':8081'
sudo ss -lunpt | grep ':53'
curl -I http://192.168.29.250:8081/admin/  # expect 200/302
```

**Outcome:** Pi-hole answers DNS on your LAN and (optionally) on the Tailscale IP. UI is at `http://<ip>:8081/admin`.

---

# Part C — Local DNS for your private hostname

### C1) Add an A record in Pi-hole

Pi-hole Admin → **Local DNS → DNS Records**:

- If you want remote access over Tailscale (recommended):

  ```
  nextcloud.homelab.ansh.com   <tailscale-ip>
  ```

- (Optional) If you also want fast resolution on your LAN:

  ```
  nextcloud.homelab.ansh.com   192.168.29.250
  ```

  > Serving both returns two A records; remote clients will use the Tailscale one, LAN clients use the LAN one.

### C2) Make your client use Pi-hole via Tailscale Split-DNS

**Tailscale Admin → DNS**

- **Nameserver:** `<tailscale-ip>` (your Pi-hole’s Tailscale IP)
- **Restrict to domain (Split DNS):** `homelab.ansh.com`
- (Optional) Enable “Override local DNS”.

**Verify from your Mac (on Tailscale):**

```bash
dig nextcloud.homelab.ansh.com +short
# expect <tailscale-ip> (and possibly 192.168.29.250 if you added both)
```

**Outcome:** Only Tailnet devices resolve your private domain; the rest of the world knows nothing.

---

# Part D — Prepare a dedicated data path for Nextcloud AIO

### D1) Create the folder on SSD with correct ownership (AIO uses uid/gid 33)

```bash
sudo mkdir -p /mnt/ssd/nextcloud
sudo chown -R 33:33 /mnt/ssd/nextcloud
sudo chmod 750 /mnt/ssd/nextcloud
```

**Outcome:** Nextcloud will store user files under `/mnt/ssd/nextcloud`.

---

# Part E — Deploy Nextcloud AIO (Apache bound to localhost)

### E1) Compose for the AIO mastercontainer

The master spins up all child containers. We bind Apache to **127.0.0.1:11000** so it’s not reachable directly.

`docker-compose.nextcloud.yaml`:

```yaml
services:
  nextcloud-aio-mastercontainer:
    image: ghcr.io/nextcloud-releases/all-in-one:latest
    init: true
    restart: always
    container_name: nextcloud-aio-mastercontainer
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    network_mode: bridge
    ports:
      - 8082:8080 # AIO setup UI (self-signed)
    environment:
      APACHE_PORT: 11000
      APACHE_IP_BINDING: 127.0.0.1
      SKIP_DOMAIN_VALIDATION: "true"
      NEXTCLOUD_DATADIR: /mnt/ssd/nextcloud

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer
```

Start it:

```bash
docker compose -f docker-compose.nextcloud.yaml up -d
```

### E2) Run the installer

Open the AIO UI:

```
https://<server-ip>:8082
```

(Self-signed; proceed.) Finish the installation.

**Outcome:** Nextcloud is running, but only Apache on `127.0.0.1:11000` can serve it. Perfect for a reverse proxy.

---

# Part F — Put Caddy in front (HTTPS via internal CA, still private)

### F1) Compose (Caddy in host network mode)

You already have a Caddy container in host mode. We’ll use an **internal CA** and reverse proxy to `127.0.0.1:11000`.

Caddyfile **(important: no `:443` in the site label!)**:

```caddyfile
{
  acme_ca internal
}

nextcloud.homelab.ansh.com {
  reverse_proxy 127.0.0.1:11000
}
```

Reload Caddy:

```bash
docker exec -it caddy caddy reload --config /etc/caddy/Caddyfile
```

**Outcome:** Caddy serves `https://nextcloud.homelab.ansh.com` privately with an internally-signed cert and proxies to Apache on localhost.

---

# Part G — Trust the TLS chain (so the browser padlock is green)

### G1) Export Caddy’s root CA

```bash
docker exec caddy cat /data/pki/authorities/local/root.crt > ./caddy-root-ca.crt
```

### G2) Install on your client(s)

- **macOS:** Keychain Access → _System_ → import `caddy-root-ca.crt` → double-click → “Always Trust”.
- **Windows:** `mmc` → Certificates (Local Computer) → Trusted Root Certification Authorities → Import.
- **Linux:** `sudo cp caddy-root-ca.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates`.
- **iOS/Android:** import as a CA certificate in system settings (then “enable full trust” on iOS).

**Outcome:** Your browser trusts `https://nextcloud.homelab.ansh.com` with no warnings.

---

# Part H — Final verification

### H1) DNS resolution (from your Mac on Tailscale)

```bash
dig nextcloud.homelab.ansh.com +short
# expect the Tailscale IP (and optionally the LAN IP)
```

### H2) Caddy is listening

```bash
sudo ss -ltnp | grep -E ':80|:443'          # should show caddy
```

### H3) App is reachable

```bash
curl -I https://nextcloud.homelab.ansh.com --insecure
# expect 200/302 headers from Nextcloud (through Caddy)
```

### H4) Pi-hole DNS is private

```bash
sudo ss -lunpt | grep ':53'
# only 192.168.29.250:53 and/or <tailscale-ip>:53; nothing on 0.0.0.0:53
```

**Outcome:** Private DNS + private HTTPS path end-to-end, no public exposure.

---

## Optional Hardening (recommended, can be done now)

- **UFW** to enforce “Tailnet-only” ingress for 22/80/443/53:

  ```bash
  sudo ufw default deny incoming
  sudo ufw allow in on tailscale0 to any port 22 proto tcp
  sudo ufw allow in on tailscale0 to any port 80,443 proto tcp
  sudo ufw allow in on tailscale0 to any port 53 proto {udp,tcp}
  sudo ufw enable
  ```

- **Keep Caddy** as the only process binding 80/443; Pi-hole UI stays on 8081.
- **Backups:** Use AIO’s backup section or borg/restic to back up `/mnt/ssd/nextcloud` + your AIO config volume.

---

## What this achieves (by design)

- **No public domain / no public exposure.** Your hostname only resolves inside your Tailnet via Pi-hole Split-DNS.
- **Double encryption:** WireGuard (Tailscale) + HTTPS (Caddy internal CA).
- **Principle of least exposure:** App backends bind to `127.0.0.1`, Caddy is the only ingress, and only via Tailscale.
- **Auditable & reproducible:** Every component is declared in compose/Caddyfile with clear binds.

---

> **Next step (for later):** We can extend this pattern to _multiple services_ behind the same Caddy, each with their own private hostname (and only reachable over Tailscale). When you’re ready, we’ll add those Caddy site blocks and Pi-hole records.
