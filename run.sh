#!/bin/bash
set -e

echo "setting up tc in eth0..."

# wipe old rules
tc qdisc del dev eth0 root 2>/dev/null || true

tc qdisc add dev eth0 root netem delay 100ms 30ms distribution normal

echo "done. current config:"

tc qdisc show dev eth0

exec /node/main
