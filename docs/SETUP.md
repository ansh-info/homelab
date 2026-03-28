# Host Setup

This guide documents how to prepare a fresh Linux machine to run this homelab. It covers the host bootstrap sequence before any Portainer stack is deployed.

For the shared placeholder vocabulary used in this file, see [VARIABLES.md](VARIABLES.md).

The target outcome at the end of this guide is:

- Docker is installed and working.
- Portainer is installed and reachable.
- Tailscale is installed and the host has joined the tailnet.
- The host filesystem has the required persistent storage layout.
- UFW is configured for the private ingress model.
- The shared external Docker network `proxy` exists.

## Scope

Use this guide when:

- rebuilding the current homelab machine from scratch
- migrating the homelab to a new machine
- validating that a fresh host is ready before deploying stacks

This guide does not cover stack-specific deployment details. Those live in the stack docs under [docs/stacks](stacks).

## Placeholder Variables

These placeholders are used throughout the documentation:

- `${HOSTNAME}`: Linux hostname for the server
- `${TAILSCALE_IP}`: Tailscale IPv4 address assigned to the host
- `${DOMAIN_ROOT}`: internal domain suffix used by Pi-hole and NPM
- `${DATA_ROOT}`: base path for persistent service data
- `${MEDIA_ROOT}`: base path for large media libraries
- `${STACK_ROOT}`: base path for stack-specific persistent data
- `${PIHOLE_ETC_ROOT}`: Pi-hole config path on the host
- `${PIHOLE_DNSMASQ_ROOT}`: Pi-hole dnsmasq config path on the host

## Current Example Values

These are example values from the current homelab. They are examples, not hard requirements:

```text
${HOSTNAME}=homelab
${TAILSCALE_IP}=100.123.147.108
${DOMAIN_ROOT}=homelab.ansh-info.com
${DATA_ROOT}=/mnt/ssd
${MEDIA_ROOT}=/mnt/ssd/docker-volumes/arr
${STACK_ROOT}=/mnt/ssd/docker-compose
${PIHOLE_ETC_ROOT}=/mnt/ssd/docker-volumes/pihole/etc-pihole
${PIHOLE_DNSMASQ_ROOT}=/mnt/ssd/docker-volumes/pihole/etc-dnsmasq.d
```

## Build Order

Prepare the host in this order:

1. Install baseline packages.
2. Prepare disks and mount points.
3. Install Docker Engine and Docker Compose support.
4. Install Portainer.
5. Install Tailscale and join the tailnet.
6. Configure firewall rules.
7. Create the shared Docker network.
8. Create persistent directories for each stack.
9. Run verification before deploying any stack.

## 1. Baseline Packages

Install the packages you want available on the host for basic operations and troubleshooting.

Example:

```bash
sudo apt update
sudo apt install -y \
  ca-certificates \
  curl \
  git \
  gnupg \
  lsb-release \
  ufw \
  dnsutils \
  sqlite3 \
  jq
```

Why these matter:

- `curl` and `dnsutils` are used constantly for DNS and proxy debugging.
- `ufw` is used to enforce the Tailscale-only ingress model.
- `sqlite3` is useful for inspecting Pi-hole data if needed.
- `jq` is useful for Docker and API inspection.

Verify:

```bash
which curl dig docker jq
```

## 2. Storage Layout

Before deploying any stack, decide where persistent data will live. Keep config, database, and media paths stable across rebuilds.

Recommended model:

- `${DATA_ROOT}` for service data on persistent storage
- `${MEDIA_ROOT}` for large media libraries and downloads
- `${STACK_ROOT}` for stack-specific config roots

Example directory preparation:

```bash
sudo mkdir -p ${STACK_ROOT}/pihole/etc-pihole
sudo mkdir -p ${STACK_ROOT}/pihole/etc-dnsmasq.d
sudo mkdir -p ${DATA_ROOT}/npm/data
sudo mkdir -p ${DATA_ROOT}/npm/letsencrypt
sudo mkdir -p ${MEDIA_ROOT}
sudo mkdir -p ${DATA_ROOT}/immich/model-cache
sudo mkdir -p ${DATA_ROOT}/nextcloud
```

Additional application directories are documented in their stack-specific guides.

Verify:

```bash
ls -ld ${STACK_ROOT} ${DATA_ROOT} ${MEDIA_ROOT}
```

## 3. Install Docker

Use the official Docker installation path for the target distro. The exact package commands may change over time, so verify against Docker's current Linux install docs when rebuilding.

Post-install checks:

```bash
docker version
docker info
docker compose version
```

If you want to run Docker without `sudo`, add your user to the `docker` group and re-login:

```bash
sudo usermod -aG docker $USER
```

Verify:

```bash
docker ps
```

## 4. Install Portainer

Portainer is the primary deployment interface for this homelab. Stacks are expected to be created and updated through the Portainer UI.

This homelab uses two Portainer run modes:

- normal mode: Portainer runs on the shared `proxy` Docker network without published host ports
- recovery mode: Portainer is temporarily restarted with `9443` and `8000` published so it can be reached directly over Tailscale when NPM or DNS is broken

### Normal operating mode

This is the preferred day-to-day pattern:

```bash
docker volume create portainer_data

docker run -d \
  --name portainer \
  --network proxy \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts
```

Why this is preferred:

- Portainer stays internal to the Docker networking model
- it can be reverse-proxied like other internal services if desired
- it avoids keeping management ports published all the time

### Temporary recovery mode

If Pi-hole or NPM is broken and Portainer is no longer reachable through the normal private hostname path, temporarily re-run it with published ports:

```bash
docker stop portainer
docker rm portainer

docker run -d \
  --name portainer \
  --restart=always \
  -p 8000:8000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts
```

Then access it through:

- `https://${TAILSCALE_IP}:9443`

This recovery mode is useful when:

- Pi-hole is down
- NPM is down
- private service hostnames are not resolving
- you need Portainer in order to fix the stacks that normally make Portainer reachable

Once the incident is fixed, switch Portainer back to the normal internal mode:

```bash
docker stop portainer
docker rm portainer

docker run -d \
  --name portainer \
  --network proxy \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts
```

After startup in either mode:

- open Portainer on the host
- complete the initial admin setup
- connect it to the local Docker environment

Verify:

```bash
docker ps --filter name=portainer
```

Note:

- Portainer itself is currently not part of the compose tree in this repo.
- Keep its data volume backed up separately from stack-managed volumes.
- Portainer is operationally upstream of the stacks it manages, so keep a direct recovery path available.

## 5. Install Tailscale

Tailscale is the private network layer for the homelab. The intended access model is to reach the homelab only over the tailnet or local LAN, not by exposing each application publicly.

Install Tailscale using the current official Linux install path, then join the machine to the tailnet.

Post-install checks:

```bash
tailscale status
tailscale ip -4
```

Record the assigned Tailscale IPv4 address. That becomes `${TAILSCALE_IP}` in the rest of the docs.

Important host DNS note:

- Avoid letting Tailscale silently override host DNS if it breaks the Pi-hole design.
- The current homelab expects the host resolver to remain stable and Pi-hole to own local homelab DNS behavior.

If needed, check:

```bash
resolvectl status
```

### Configure Tailscale Split DNS for clients

For this homelab, client devices need a DNS path that sends queries for `${DOMAIN_ROOT}` to Pi-hole at `${TAILSCALE_IP}`.

The current working model uses Tailscale admin DNS with a Split DNS entry:

- domain: `${DOMAIN_ROOT}`
- nameserver: `${TAILSCALE_IP}`

With current example values, that means:

- domain: `homelab.ansh-info.com`
- nameserver: `100.123.147.108`

Why this matters:

- Pi-hole is the DNS authority for `*.${DOMAIN_ROOT}`
- Tailscale Split DNS tells client devices where to send those queries
- if this Split DNS entry is removed, client devices may stop resolving homelab service names even though Pi-hole and NPM are healthy

Client-side verification after enabling Split DNS:

```bash
dig +short immich.${DOMAIN_ROOT}
dig +short immich.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

Expected:

```text
${TAILSCALE_IP}
```

## Host DNS Baseline

This homelab expects the Linux host to keep `systemd-resolved` enabled while avoiding the stub-listener conflict on port `53`.

The stable model is:

- `systemd-resolved` stays enabled
- `DNSStubListener` is disabled
- Pi-hole owns port `53`
- the host resolver points at `127.0.0.1`
- Tailscale should not override host DNS in a way that breaks this design

### Why this matters

If the host keeps the `systemd-resolved` stub listener enabled, it can bind port `53` and prevent the Pi-hole container from starting cleanly.

If Tailscale overwrites host DNS unexpectedly, the host may stop using Pi-hole for local homelab resolution and debugging becomes confusing.

### Disable the stub listener without disabling `systemd-resolved`

Edit:

```bash
sudo nano /etc/systemd/resolved.conf
```

Set:

```ini
[Resolve]
DNSStubListener=no
```

Restart:

```bash
sudo systemctl restart systemd-resolved
```

### Ensure `/etc/resolv.conf` points to the non-stub resolver file

```bash
sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

Verify:

```bash
ls -l /etc/resolv.conf
cat /etc/resolv.conf
```

Expected:

- `/etc/resolv.conf` points to `/run/systemd/resolve/resolv.conf`

### Point the host at Pi-hole

Edit:

```bash
sudo nano /etc/systemd/resolved.conf
```

Set:

```ini
[Resolve]
DNS=127.0.0.1
FallbackDNS=1.1.1.1 9.9.9.9
DNSStubListener=no
```

Restart:

```bash
sudo systemctl restart systemd-resolved
```

Verify:

```bash
resolvectl status
```

Expected:

- global DNS server includes `127.0.0.1`
- Tailscale MagicDNS `100.100.100.100` is not unexpectedly overriding the host resolver path

### Prevent Tailscale from taking over host DNS when needed

If the host keeps switching away from the intended resolver path, re-run Tailscale with DNS override disabled:

```bash
sudo tailscale up --accept-dns=false
```

If the host uses additional non-default Tailscale options, re-run `tailscale up` with the full set of required flags, not just `--accept-dns=false`.

## 6. Configure Firewall

The host uses a deny-by-default firewall posture with narrow allow rules on `tailscale0`.

Expected model:

- allow SSH only from trusted Tailscale clients
- allow `53/tcp` and `53/udp` on `tailscale0` for Pi-hole
- allow `80/tcp` and `443/tcp` on `tailscale0` for NPM
- deny unrelated public ingress by default

Example baseline:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow in on tailscale0 to any port 53 proto tcp
sudo ufw allow in on tailscale0 to any port 53 proto udp
sudo ufw allow in on tailscale0 to any port 80 proto tcp
sudo ufw allow in on tailscale0 to any port 443 proto tcp
```

SSH rules depend on which client devices should be able to connect.

Verify:

```bash
sudo ufw status verbose
```

## 7. Create the Shared Docker Network

Reverse-proxied services are expected to join a shared external Docker network named `proxy`.

Create it once on the host before deploying stacks:

```bash
docker network create proxy
```

Verify:

```bash
docker network ls
docker network inspect proxy
```

## 8. Prepare Persistent Stack Paths

Before importing stacks into Portainer, ensure the host paths referenced by the compose files exist.

At minimum, this homelab currently expects paths for:

- Pi-hole config and dnsmasq data
- Nginx Proxy Manager data and certificates
- Arr stack config, downloads, and media libraries
- Immich uploads, database data, and model cache
- Nextcloud data

Do not wait until after stack deployment to create core directories. Missing host paths make troubleshooting much harder and can create permission drift.

## 9. Pre-Deploy Verification Checklist

Before deploying the first stack, verify all platform prerequisites:

```bash
hostname
docker ps
docker network inspect proxy >/dev/null && echo "proxy network ok"
tailscale ip -4
sudo ufw status verbose
```

You should be able to answer yes to all of these:

- Does the host have stable persistent storage mounted where the stacks expect it?
- Is Docker healthy and able to run containers?
- Is Portainer running?
- Is the machine joined to Tailscale?
- Does the `proxy` network exist?
- Are the firewall rules aligned with the private ingress model?

## Common Pitfalls

### Tailscale IP binding race conditions

Avoid binding Docker services directly to the Tailscale IP in compose files. If Docker starts before `tailscale0` is ready, the containers can fail to bind and fail to start cleanly.

Related examples of the fragile pattern:

```yaml
- "100.123.147.108:53:53/tcp"
- "100.123.147.108:53:53/udp"
- "100.123.147.108:80:80"
- "100.123.147.108:443:443"
```

The stable pattern is:

```yaml
- "53:53/tcp"
- "53:53/udp"
- "80:80"
- "443:443"
```

Then restrict exposure with UFW on `tailscale0`.

### Pi-hole custom dnsmasq configs not loading

If you mount `/etc/dnsmasq.d` in Pi-hole v6, you must also set:

```yaml
FTLCONF_misc_etc_dnsmasq_d: "true"
```

Without it, your custom wildcard or local DNS config may exist on disk but be ignored by Pi-hole.

### Host DNS changes after Tailscale install

If host DNS unexpectedly starts using Tailscale MagicDNS or an unexpected upstream resolver, verify:

```bash
resolvectl status
```

### Shared network missing

If a stack references an external Docker network that does not exist, Portainer deployment will fail. Create `proxy` first.

## Next Step

Once the host is ready, continue with [NETWORKING.md](NETWORKING.md), then deploy the foundational stacks:

1. Pi-hole
2. Nginx Proxy Manager
3. Application stacks
