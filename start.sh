#!/bin/sh

mkdir -p /var/lib/app/tailscale /var/run/tailscale /var/lib/app/adguardhome /var/lib/app/caddy


# ref: https://community.fly.io/t/is-it-possible-to-use-my-own-init/12082/4
if [ "$$" -eq 1 ]; then
    exec /init "$@"
else
    exec unshare --pid sh -c '
        # set up /proc and start the real init in the background
        unshare --mount-proc /init "$@" &
        child="$!"
        # forward signals to the real init
        trap "kill -INT \$child" INT
        trap "kill -TERM \$child" TERM
        # wait until the real init exits
        # ("wait" returns early on signals; "kill -0" checks if the process exists)
        until wait "$child" || ! kill -0 "$child" 2>/dev/null; do :; done
    ' sh "$@"
fi