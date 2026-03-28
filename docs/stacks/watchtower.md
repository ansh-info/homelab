# Watchtower Stack

This guide documents the Watchtower deployment in the homelab and the operational risks that come with automated container updates.

For the shared placeholder vocabulary used in this file, see [../VARIABLES.md](../VARIABLES.md).

Reference compose file:

- [docker-compose/watchtower/docker-compose.yml](../../docker-compose/watchtower/docker-compose.yml)

## Purpose

Watchtower monitors Docker containers and updates eligible images automatically. In this homelab it is configured with label-based update control and a daily interval.

## Dependencies

Watchtower depends on:

- Docker and Portainer
- access to `/var/run/docker.sock`
- a deliberate labeling strategy if label-based updates are expected

## Placeholder Variables

- `${HOSTNAME}`: Linux hostname of the homelab server
- `${WATCHTOWER_INTERVAL_SECONDS}`: update interval in seconds
- `${TZ}`: host timezone

## Current Example Values

```text
${HOSTNAME}=homelab
${WATCHTOWER_INTERVAL_SECONDS}=86400
${TZ}=Asia/Kolkata
```

## Compose Highlights

Current important details from the stack:

- image: `containrrr/watchtower`
- Docker socket mounted from the host
- interval set to `86400` seconds
- `--cleanup` enabled
- `--label-enable` enabled
- `--debug` enabled

Meaning:

- updates are not applied blindly to every container unless labeling is configured accordingly
- old images are cleaned up after updates
- logs are verbose enough for debugging

## Portainer Deployment

Deploy through Portainer using:

- [docker-compose/watchtower/docker-compose.yml](../../docker-compose/watchtower/docker-compose.yml)

After deployment:

```bash
docker ps --filter name=watchtower
docker logs --tail 100 watchtower
```

## Operational Warning

Watchtower can change running infrastructure without a manual redeploy. That is useful, but risky.

Be careful with:

- stateful services like databases
- reverse proxy and DNS infrastructure
- stacks where config expectations can drift from the checked-in compose files

For this homelab, automatic updates should be treated as an operational choice, not a default assumption of safety.

## Verification

Run on `${HOSTNAME}`:

```bash
docker ps --filter name=watchtower
docker logs --tail 100 watchtower
```

If label-based updating is intended, verify the target containers are labeled correctly in their stack definitions or runtime metadata.

## Common Failure Modes

### Watchtower runs but updates nothing

Likely causes:

- `--label-enable` is set, but target containers do not have the expected labels

### A service changes unexpectedly after an update

Likely causes:

- automatic image update introduced a breaking change
- a stateful service was updated without coordinated verification

## Recovery Procedure

Use this order:

1. Inspect Watchtower logs for the affected time window.
2. Identify which container was updated.
3. Compare the running image tag or digest with the expected version.
4. Redeploy the affected stack intentionally if rollback or pinning is needed.

## Related Docs

- [docs/OPERATIONS.md](../OPERATIONS.md)
