# Operations

This guide documents day-two operations for the homelab. It assumes the host is already bootstrapped, the foundational networking model is in place, and the stacks are managed primarily through Portainer.

For the shared placeholder vocabulary used in this file, see [VARIABLES.md](VARIABLES.md).

## Scope

This guide covers:

- normal stack deployment and redeployment
- Portainer-first operational workflows
- Docker CLI fallback workflows
- logs, health checks, and network inspection
- backups and restore priorities
- common incident patterns and recovery order

## Operating Principles

- Portainer is the primary interface for deploying and editing stacks.
- The Docker CLI is the fallback interface for inspection, debugging, and recovery.
- DNS and ingress layers come before application layers during recovery.
- Persistent volumes and env files are part of the real system state and must be backed up.
- Changes to reverse proxy, DNS, and storage paths should be treated carefully because they affect multiple stacks.

## Portainer-First Workflows

### Portainer runtime modes

This homelab uses two Portainer access modes.

Normal mode:

- Portainer runs on the `proxy` Docker network
- no host ports are published
- access depends on the internal DNS and reverse-proxy path being healthy

Recovery mode:

- Portainer is temporarily restarted with `9443` and `8000` published
- access happens directly through `https://${TAILSCALE_IP}:9443`
- this is used when Pi-hole or NPM is broken and the normal path to Portainer is unavailable

Normal mode command:

```bash
docker run -d \
  --name portainer \
  --network proxy \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts
```

Recovery mode command:

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

Return to normal mode after the incident:

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

### Deploy a new stack

Use Portainer when:

- creating a new stack from a compose file
- editing stack environment or volume settings
- redeploying after configuration changes

Recommended workflow:

1. confirm the compose file in git is current
2. confirm required host paths exist
3. confirm required env files exist
4. deploy or update the stack in Portainer
5. verify container status
6. verify DNS and NPM only if the stack should be privately exposed

### Redeploy an existing stack

Typical reasons:

- changed compose file
- changed environment variable
- updated mounted paths
- updated image version or operational settings

After a redeploy, always verify:

- container status
- logs
- network membership if reverse proxy access is expected
- DNS and hostname routing if externally consumed through the tailnet

### Inspect a stack in Portainer

Use Portainer for:

- stack status
- container logs
- quick restarts
- environment review
- volume and network visibility

## Docker CLI Fallback Workflows

Use the CLI when:

- Portainer is unavailable
- you need faster inspection
- you are validating a network or resolver issue
- you need precise logs or command-line queries
- you need to recover the path to Portainer itself

Core commands:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker logs --tail 100 <container-name>
docker inspect <container-name>
docker network inspect proxy
docker exec <container-name> sh
```

Useful service-level checks:

```bash
sudo ss -lntup | egrep ':(53|80|443)\b'
sudo ufw status verbose
resolvectl status
tailscale status
```

## Verification Patterns

### DNS layer

```bash
dig +short google.com @${TAILSCALE_IP}
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
dig +short immich.${DOMAIN_ROOT} @${TAILSCALE_IP}
```

### Proxy layer

```bash
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
curl -vk --resolve immich.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://immich.${DOMAIN_ROOT}/
```

### Container and network layer

```bash
docker ps
docker network inspect proxy
docker logs --tail 100 nginx-proxy-manager
docker logs --tail 100 pihole
```

## Routine Operations

### Restart a single container

```bash
docker restart <container-name>
```

Use when:

- a service needs a simple restart after a small config change
- you changed a mounted file that only one service consumes

Do not treat restarts as a substitute for diagnosis. If the problem recurs, inspect logs and state.

### Review logs

```bash
docker logs --tail 100 <container-name>
```

For long-running diagnosis:

```bash
docker logs -f <container-name>
```

### Check health status

```bash
docker inspect --format='{{json .State.Health}}' <container-name>
```

Only works for containers that define a health check.

### Inspect a network problem

```bash
docker network inspect proxy
```

Use this when:

- NPM cannot reach a backend
- a service is up but not proxyable
- a stack appears healthy but hostname-based routing fails

## Backup Targets

Back up these categories first.

### Highest priority

- Pi-hole config under `${PIHOLE_ETC_ROOT}`
- Pi-hole dnsmasq config under `${PIHOLE_DNSMASQ_ROOT}`
- NPM data under `${NPM_DATA_ROOT}`
- NPM certificates under `${NPM_CERT_ROOT}`
- environment files like Immich `stack.env`

### Medium priority

- app config directories under `${CONFIG_ROOT}`
- Nextcloud persistent data
- Immich upload and database storage

### Large-data priority

- media libraries
- download directories

These are important, but the restore order differs from the configuration layers. Restore DNS and ingress first so application recovery is easier to validate.

## Restore Priorities

When rebuilding after failure, restore in this order:

1. host OS, storage mounts, Docker, Portainer, and Tailscale
2. firewall and shared Docker network
3. Pi-hole config and wildcard DNS rules
4. NPM data and certificates
5. core app configs and env files
6. application stacks
7. large media libraries and secondary data if needed

This order matters because:

- app hostname tests are not reliable until Pi-hole and NPM are restored
- reverse-proxy routing is easier to validate before restoring every single application detail

## Incident Playbooks

### Incident: private service names stop resolving

Use this order:

1. `tailscale status`
2. `dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}`
3. `docker ps --filter name=pihole`
4. `docker exec pihole sh -lc 'dig +short seerr.${DOMAIN_ROOT} @127.0.0.1'`
5. `docker exec pihole sh -lc 'env | grep FTLCONF_misc_etc_dnsmasq_d'`
6. confirm `${PIHOLE_DNSMASQ_ROOT}/99-homelab.conf` exists

Likely root causes:

- wildcard DNS rule missing
- Pi-hole v6 not loading `/etc/dnsmasq.d`
- client DNS cache or wrong resolver path

### Incident: names resolve, but proxied services do not load

Use this order:

1. `sudo ss -lntup | egrep ':(80|443)\b'`
2. `docker ps --filter name=nginx-proxy-manager`
3. `curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/`
4. `docker network inspect proxy`
5. `docker logs --tail 100 nginx-proxy-manager`
6. `docker logs --tail 100 <service-name>`

Likely root causes:

- missing or wrong NPM proxy host
- backend service not on `proxy`
- wrong upstream host or port
- backend application unhealthy

### Incident: Portainer itself is unreachable through the normal hostname path

Use this order:

1. decide whether the failure is caused by Pi-hole, NPM, or both
2. temporarily restart Portainer in recovery mode with `9443` and `8000` published
3. access Portainer at `https://${TAILSCALE_IP}:9443`
4. fix the broken stack or proxy path from Portainer
5. switch Portainer back to normal mode on the `proxy` network after recovery

Recovery commands:

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

### Incident: service worked before reboot and now does not

Use this order:

1. inspect the compose file for direct Tailscale-IP port binding
2. confirm services bind to host ports, not `${TAILSCALE_IP}:port`
3. confirm UFW rules still enforce the privacy boundary
4. inspect Tailscale status

Likely root cause:

- boot-time race condition caused by binding ports directly to the Tailscale IP

### Incident: host DNS behaves strangely after Tailscale changes

Use this order:

1. `resolvectl status`
2. `ls -l /etc/resolv.conf`
3. confirm `DNSStubListener=no`
4. confirm host DNS still points to `127.0.0.1`
5. if needed, re-run `tailscale up --accept-dns=false`

Likely root causes:

- Tailscale DNS override changed the host resolver path
- resolver baseline drifted away from the Pi-hole-first model

## Change Management Notes

Before changing a stack:

- identify whether the change affects DNS, proxying, storage, or secrets
- identify whether the change is reversible
- verify whether the changed path or env var is shared with other services

Be especially careful with:

- Pi-hole DNS config
- NPM certificates and proxy hosts
- storage paths used by multiple media services
- env files used by stateful apps like Immich

## Recommended Periodic Checks

Run these periodically:

```bash
tailscale status
sudo ufw status verbose
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker network inspect proxy >/dev/null && echo "proxy network ok"
```

And for DNS and ingress:

```bash
dig +short seerr.${DOMAIN_ROOT} @${TAILSCALE_IP}
curl -vk --resolve seerr.${DOMAIN_ROOT}:443:${TAILSCALE_IP} https://seerr.${DOMAIN_ROOT}/
```

## Related Docs

- [README.md](../README.md)
- [SETUP.md](SETUP.md)
- [NETWORKING.md](NETWORKING.md)
- [stacks/portainer.md](stacks/portainer.md)
- [stacks/pihole.md](stacks/pihole.md)
- [stacks/nginx-proxy-manager.md](stacks/nginx-proxy-manager.md)
- [stacks/jellyfin-arr-stack.md](stacks/jellyfin-arr-stack.md)
- [stacks/immich.md](stacks/immich.md)
- [stacks/nextcloud-aio.md](stacks/nextcloud-aio.md)
- [stacks/watchtower.md](stacks/watchtower.md)
