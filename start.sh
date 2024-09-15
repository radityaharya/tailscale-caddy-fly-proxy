#!/bin/sh

# Ensure necessary directories exist
mkdir -p /var/lib/app/tailscale /var/run/tailscale /var/lib/app/adguardhome

/app/tailscaled --state=/var/lib/app/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &

until /app/tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=internal
do
    sleep 0.1
done

echo "Spinning up adguardhome"
/app/AdGuardHome -c /var/lib/app/adguardhome/AdGuardHome.yaml -w /var/lib/app/adguardhome &

echo "Spinning up caddy"
caddy run --config /etc/caddy/Caddyfile &

echo "Started caddy"

tail -f /dev/null