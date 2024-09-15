# Tailscale Caddy Fly.io Proxy

This is a simple proxy that routes services that are in the [tailnet](https://tailscale.com/kb/1136/tailnet). It has built-in AdGuard Home, which is used as a DNS server, that you can use as your [tailscale's nameserver](https://tailscale.com/kb/1054/dns) or use it in [split DNS mode](https://tailscale.com/kb/1054/dns#restricted-nameservers).

## Getting Started

1. Clone this repository
```bash
git clone https://github.com/radityaharya/tailscale-caddy-fly-proxy.git
cd tailscale-caddy-fly-proxy
```

2. Copy Caddyfile.example to Caddyfile
```bash
cp Caddyfile.example Caddyfile
```

3. Edit Caddyfile to add your services

4. Create a new Fly.io app (select copy from existing configuration)
```bash
flyctl launch --ha-false
```

5. Set the following environment variables
```bash
flyctl secrets set TAILSCALE_AUTHKEY=<your-tailscale-auth-key>
```

6. Deploy the app
```bash
flyctl deploy --ha=false
```

7. Go to [Tailscale admin console](https://login.tailscale.com/admin/machines) and save your newly added machine's IP address

8. Setup AdGuard Home by going to `http://<your-tailscale-app-ip>:3000` and set the dashboard listen address other than `80` as it will be used by Caddy, for example you can set it to `8053`

9. Go to Adguard home dashboard at `http://<your-tailscale-app-ip>:8053`. Go to Filters > DNS Rewrites and add the following rewrites:
```
*.fly.local -> <your-tailscale-app-ip>
```

10. Go to Tailscale admin console > [DNS](https://login.tailscale.com/admin/dns) and add a custom nameserver with the following configuration:
```
Name: <your-tailscale-app-ip>

(You can skip this if you don't want to use split DNS, and use AdGuard Home as your nameserver)
Restrict to domain: true

Domains: fly.local
```

11. You should be able to access your services defined in `Caddyfile`



