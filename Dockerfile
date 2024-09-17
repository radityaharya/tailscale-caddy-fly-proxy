# Build Caddy with plugins
FROM caddy:2.8.4-builder AS builder
RUN xcaddy build \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/tuzzmaniandevil/caddy-dynamic-clientip

# Prepare AdGuard binary
FROM alpine:3.14 AS adguard
WORKDIR /app
RUN wget https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.52/AdGuardHome_linux_amd64.tar.gz \
  && tar -xzf AdGuardHome_linux_amd64.tar.gz \
  && rm AdGuardHome_linux_amd64.tar.gz

# Final stage
FROM alpine:3.14
ARG S6_OVERLAY_VERSION=3.2.0.0
ARG S6_OVERLAY_ARCH="x86_64"

WORKDIR /app
RUN apk update && apk add --no-cache \
  ca-certificates \
  iptables \
  ip6tables \
  unzip \
  wget \
  gcompat \
  xz \
  && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz -O /tmp/s6-overlay-noarch.tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
  && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz -O /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz \
  && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz -O /tmp/s6-overlay-symlinks-noarch.tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz \
  && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz -O /tmp/s6-overlay-symlinks-arch.tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz \
  && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/syslogd-overlay-noarch.tar.xz -O /tmp/syslogd-overlay-noarch.tar.xz \
  && tar -C / -Jxpf /tmp/syslogd-overlay-noarch.tar.xz \
  && rm -rf /tmp/*.tar.xz

# Copy other necessary files
COPY ./start.sh /app/start.sh
COPY ./certs /app/certs
COPY ./monitor /app/monitor

# Copy Caddy binary and configuration
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY ./Caddyfile /etc/caddy/Caddyfile
RUN caddy validate --config /etc/caddy/Caddyfile

# Copy AdGuard binary
COPY --from=adguard /app/AdGuardHome/AdGuardHome /app/AdGuardHome

# Copy Tailscale binaries
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /app/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /app/tailscale

# Monitoring
COPY --from=docker.io/grafana/grafana:main /usr/share/grafana /usr/share/grafana
COPY --from=docker.io/grafana/promtail:main /usr/bin/promtail /usr/bin/promtail
COPY --from=docker.io/grafana/loki:main /usr/bin/loki /usr/bin/loki
COPY --from=docker.io/prom/prometheus:main /bin/prometheus /usr/bin/prometheus
COPY --from=docker.io/prom/node-exporter:latest /bin/node_exporter /usr/bin/node_exporter
COPY --from=docker.io/prom/alertmanager:latest /bin/alertmanager /usr/bin/alertmanager
COPY --from=docker.io/prom/pushgateway:latest /bin/pushgateway /usr/bin/pushgateway
COPY --from=ghcr.io/henrywhitaker3/adguard-exporter:latest /adguard-exporter /usr/bin/adguard-exporter

# Create necessary directories and set permissions
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/app/tailscale /var/lib/app/adguardhome /var/lib/app/caddy \
  && chmod +x /app/start.sh

# Copy s6-rc service definitions and set executable permissions
COPY s6-overlay/s6-rc.d /etc/s6-overlay/s6-rc.d
RUN chmod +x /etc/s6-overlay/s6-rc.d/*/run

EXPOSE 80

CMD ["/app/start.sh"]