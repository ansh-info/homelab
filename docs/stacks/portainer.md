# Portainer

This guide documents how Portainer is run in the homelab, why it is treated as an operational control plane, and how to switch between normal mode and recovery mode when the usual private access path is broken.

For the shared placeholder vocabulary used in this file, see [../VARIABLES.md](../VARIABLES.md).

Portainer is not defined as a compose stack in this repo, but it is still a critical part of the system because it manages the stacks that are.

## Purpose

Portainer is the primary management interface for the homelab.

It is used for:

- deploying and updating stacks
- editing environment variables and stack definitions
- inspecting container logs and status
- restarting services during incidents

Because Portainer is used to fix the very services that normally expose it, it needs a documented fallback access path.

## Placeholder Variables

- `${HOSTNAME}`: Linux hostname of the homelab server
- `${TAILSCALE_IP}`: homelab Tailscale IP
- `${PROXY_NETWORK}`: shared Docker network

## Current Example Values

```text
${HOSTNAME}=homelab
${TAILSCALE_IP}=100.123.147.108
${PROXY_NETWORK}=proxy
```

## Persistent Data

Portainer uses a named Docker volume:

```bash
docker volume create portainer_data
```

This volume should be preserved across restarts and mode switches.

## Normal Mode

Normal mode is the preferred day-to-day setup.

Characteristics:

- Portainer runs on `${PROXY_NETWORK}`
- no host ports are published
- access depends on your internal private access path being healthy

Run command:

```bash
docker run -d \
  --name portainer \
  --network proxy \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts
```

Why this mode is preferred:

- it keeps the management surface internal
- it aligns with the rest of the private ingress model
- it avoids leaving management ports open unnecessarily

## Recovery Mode

Recovery mode is used only when the normal access path is broken.

Use it when:

- Pi-hole is down
- Nginx Proxy Manager is down
- homelab hostnames are not resolving
- Portainer cannot be reached through its normal private hostname path

Switch to recovery mode:

```bash
docker stop portainer
docker rm portainer

docker run -d \
  --name portainer \
  --restart=always \
  -p 9443:9443 \
  -p 8000:8000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts
```

Access it through:

```text
https://${TAILSCALE_IP}:9443
```

This gives you a direct management path over Tailscale even when the private DNS and reverse-proxy layers are unhealthy.

## Return to Normal Mode

After the incident is resolved, switch back:

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

## Verification

Run on `${HOSTNAME}`:

```bash
docker ps --filter name=portainer
docker logs --tail 100 portainer
docker inspect portainer
```

To check whether it is in normal or recovery mode:

- normal mode: container is attached to `${PROXY_NETWORK}` and does not publish host ports
- recovery mode: container publishes `9443` and `8000`

Useful checks:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep portainer
docker network inspect ${PROXY_NETWORK}
```

## Suggested NPM Proxy Target

In normal mode, Portainer can be reached through NPM with:

- `portainer.${DOMAIN_ROOT}` -> `portainer:9443`

### How To Fill NPM For Portainer

Use this proxy-host entry:

| Public hostname | Scheme | Forward Hostname / IP | Forward Port |
| --- | --- | --- | --- |
| `portainer.${DOMAIN_ROOT}` | `https` | `portainer` | `9443` |

Recommended NPM toggles:

- `Access List`: `Publicly Accessible`
- `Cache Assets`: enabled
- `Block Common Exploits`: enabled
- `Websockets Support`: enabled
- SSL certificate: `*.${DOMAIN_ROOT}`
- `Force SSL`: enabled
- `HTTP/2 Support`: enabled
- `HSTS Enabled`: enabled
- `HSTS Sub-domains`: enabled

Important:

- Portainer is the main exception where the upstream scheme should be `https`
- in recovery mode, the fallback access path is direct:
  - `https://${TAILSCALE_IP}:9443`
- if NPM or DNS is broken, use recovery mode instead of the normal hostname path

## Operational Notes

- Portainer is operationally upstream of the stack docs because it is how the stacks are managed.
- If Portainer is unreachable, fixing the rest of the environment becomes slower and more manual.
- Keep the direct recovery-mode command available even if you rarely need it.

## Common Failure Modes

### Portainer works normally, then disappears when DNS or NPM breaks

This is expected if you only rely on the normal private hostname path.

Fix:

- switch to recovery mode
- reach it through `https://${TAILSCALE_IP}:9443`

### Portainer container is running, but the UI is still unreachable

Likely causes:

- wrong mode for the current incident
- host firewall issue
- Tailscale connectivity issue

Checks:

```bash
tailscale status
docker ps --filter name=portainer
sudo ss -lntup | egrep ':(9443|8000)\b'
```

### Portainer is recreated and stack state appears missing

Likely cause:

- `portainer_data` was not mounted or a different volume was used

Check:

```bash
docker inspect portainer
docker volume ls | grep portainer_data
```

## Related Docs

- [docs/SETUP.md](../SETUP.md)
- [docs/OPERATIONS.md](../OPERATIONS.md)
- [docs/NETWORKING.md](../NETWORKING.md)
