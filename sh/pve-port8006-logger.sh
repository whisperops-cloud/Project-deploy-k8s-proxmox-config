#!/bin/bash

# Read and discard HTTP payload
read _

# If systemd exposed REMOTE_ADDR, use it
if [[ -n "$REMOTE_ADDR" ]]; then
    PEER="$REMOTE_ADDR"
else
    PEER="UNKNOWN"
fi

echo "$(date '+%F %T') Honeypot connection from ${PEER}" >> /var/log/pve-port8006.log
