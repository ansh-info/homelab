# 🧰 Homelab Auto-Fix for Pi-hole After Power Cuts

## 🎯 Goal

Create an **automatic fix** that runs after boot:

If Pi-hole starts broken (missing DNS ports),
→ **automatically restart ONLY the Pi-hole container**,
→ WITHOUT rebooting the server,
→ WITHOUT damaging Portainer-managed stacks.

---

### 1️⃣ A boot-time script:

`/usr/local/bin/fix-pihole-stack.sh`

This script:

- Waits (500 seconds) for:
  - Router → Online
  - WAN → Connected
  - Tailscale → Signed in
  - Docker → All containers running

- Checks whether Pi-hole:

  ✔ exists
  ✔ is running
  ✔ has correct DNS port bindings (`53->53`)

### 2️⃣ If Pi-hole is broken:

- If container exists but no DNS ports → **docker restart pihole**
- If container exists but is stopped → **docker start pihole**
- If container does NOT exist → **docker compose up -d** in your Pi-hole directory
  (`/mnt/ssd/docker-compose/pihole`)

### 3️⃣ A systemd service

`fix-pihole-stack.service`

Runs once at boot and performs the automated check+fix.

---

# 📂 Folder & Container Layout

Your Pi-hole stack lives at:

```
/mnt/ssd/docker-compose/pihole
├─ docker-compose.yml
├─ etc-pihole/
└─ etc-dnsmasq.d/
```

Pi-hole container name:

```
pihole
```

This is important for the script logic.

---

# 🛠️ Step-by-Step Solution Setup

---

## 1️⃣ Create the auto-fix script

Create the file:

```bash
sudo nano /usr/local/bin/fix-pihole-stack.sh
```

Paste this:

```bash
#!/usr/bin/env bash
set -e

# Wait so network, router, Tailscale and Docker have time to come up.
sleep 500   # 500 seconds is safe in environments with slow power recovery

PIHOLE_DIR="/mnt/ssd/docker-compose/pihole"
PIHOLE_CONTAINER_NAME="pihole"

echo "[fix-pihole] Checking Pi-hole container state..."

# Does the container exist at all?
if docker ps -a --format '{{.Names}}' | grep -q "^${PIHOLE_CONTAINER_NAME}\$"; then
  echo "[fix-pihole] Container '${PIHOLE_CONTAINER_NAME}' exists."

  # Is it running?
  if ! docker ps --format '{{.Names}}' | grep -q "^${PIHOLE_CONTAINER_NAME}\$"; then
    echo "[fix-pihole] Container exists but is not running. Starting..."
    docker start "${PIHOLE_CONTAINER_NAME}"
    exit 0
  fi

  # Is it running with correct DNS ports?
  if ! docker ps --format '{{.Names}} {{.Ports}}' \
    | grep -q "^${PIHOLE_CONTAINER_NAME} .*53->53"; then
    echo "[fix-pihole] Container running but DNS ports missing. Restarting..."
    docker restart "${PIHOLE_CONTAINER_NAME}"
    exit 0
  fi

  echo "[fix-pihole] Pi-hole is healthy with correct port bindings. Nothing to do."
  exit 0
fi

# Container does NOT exist → recreate using docker compose
echo "[fix-pihole] Pi-hole container absent. Recreating via docker compose..."
cd "$PIHOLE_DIR"
docker compose up -d
```

Make executable:

```bash
sudo chmod +x /usr/local/bin/fix-pihole-stack.sh
```

---

## 2️⃣ Create the systemd service

Create:

```bash
sudo vi /etc/systemd/system/fix-pihole-stack.service
```

Paste:

```ini
[Unit]
Description=Check and auto-fix Pi-hole docker stack after boot
After=network-online.target docker.service tailscaled.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-pihole-stack.sh

[Install]
WantedBy=multi-user.target
```

Enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable fix-pihole-stack.service
```

---

# 🧪 Testing the Fix

### Test 1 — Force Pi-hole to stop

```bash
docker stop pihole
sudo systemctl start fix-pihole-stack.service
```

Expected output:

```
Container exists but is not running. Starting...
```

### Test 2 — Force Pi-hole to start without ports

(Simulate the power-cut issue)

```bash
docker run --name pihole pihole/pihole:latest
# This will start without your compose bindings, but it will exist+run
sudo systemctl start fix-pihole-stack.service
```

Expected:

```
Container running but DNS ports missing. Restarting...
```

### Test 3 — Check logs after real boot:

```bash
journalctl -u fix-pihole-stack.service -b
```

---

# 🧩 Why This Fix Works

- Pi-hole breaks because Docker starts it **before IPs exist** → no port bindings.
- Waiting 500 seconds ensures:
  - router booted
  - internet restored
  - Tailscale connected
  - all Docker networks initialized

- Checking for `53->53` binding identifies the exact failure state.
- Restarting only the Pi-hole container avoids:
  - unnecessary reboots
  - breaking Portainer stack management
  - recreating containers

- Fully automatic: you never need to SSH in after a power outage.

---

# 🎉 Final Result

After a power cut:

1. Server boots automatically
2. Tailscale connects
3. Docker starts containers
4. Pi-hole may start in a broken state
5. **500 seconds later → script runs**
6. If Pi-hole is broken → script restarts or recreates it
7. DNS works again
8. Your homelab domains are restored automatically

No manual SSH.
No manual docker commands.
No server reboots needed.
