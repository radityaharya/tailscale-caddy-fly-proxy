FROM caddy:2-alpine AS builder
WORKDIR /app
COPY . ./
COPY ./Caddyfile /etc/caddy/Caddyfile

FROM alpine:3.14 AS adguard
WORKDIR /app
RUN wget https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.52/AdGuardHome_linux_amd64.tar.gz \
    && tar -xzf AdGuardHome_linux_amd64.tar.gz

FROM caddy:2-alpine
RUN apk update && apk add ca-certificates iptables ip6tables && rm -rf /var/cache/apk/*

COPY --from=builder /app/start.sh /app/start.sh
COPY --from=builder /etc/caddy/Caddyfile /etc/caddy/Caddyfile
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /app/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /app/tailscale
COPY --from=builder /app/certs /app/certs

# Copy AdGuard binary
COPY --from=adguard /app/AdGuardHome/AdGuardHome /app/AdGuardHome

# Create necessary directories
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/app/tailscale /var/lib/app/adguardhome

EXPOSE 80

RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]