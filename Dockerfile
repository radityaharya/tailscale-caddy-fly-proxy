# Build Caddy with plugins
FROM caddy:2.8.4-builder AS builder
RUN xcaddy build \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/tuzzmaniandevil/caddy-dynamic-clientip

# Prepare AdGuard binary
FROM alpine:3.14 AS adguard
WORKDIR /app
RUN wget https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.52/AdGuardHome_linux_amd64.tar.gz \
    && tar -xzf AdGuardHome_linux_amd64.tar.gz

# Final stage
FROM alpine:3.14
WORKDIR /app

# Install necessary packages
RUN apk update && apk add --no-cache ca-certificates iptables ip6tables

# Copy other necessary files
COPY ./start.sh /app/start.sh
COPY ./certs /app/certs

# Copy Caddy binary and configuration
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY ./Caddyfile /etc/caddy/Caddyfile
RUN caddy validate --config /etc/caddy/Caddyfile

# Copy AdGuard binary
COPY --from=adguard /app/AdGuardHome/AdGuardHome /app/AdGuardHome

# Copy Tailscale binaries
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /app/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /app/tailscale

# Create necessary directories
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/app/tailscale /var/lib/app/adguardhome /var/lib/app/caddy \
    && chmod +x /app/start.sh

EXPOSE 80

CMD ["/app/start.sh"]