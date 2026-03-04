#!/bin/bash
# Usage: lp mysql start

ORIGINAL_DIR=$(pwd)

cd ~/dev/docker
docker compose -f mysql.yml up -d

sleep 2

"$(dirname "$0")/reset.sh"

cd "$ORIGINAL_DIR"
