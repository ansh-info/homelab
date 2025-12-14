#!/usr/bin/env bash
set -e

# Wait so network, router, Tailscale and Docker have time to come up.
sleep 500 # 500 seconds is safe in environments with slow power recovery

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
	if ! docker ps --format '{{.Names}} {{.Ports}}' |
		grep -q "^${PIHOLE_CONTAINER_NAME} .*53->53"; then
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
