#!/bin/sh
set -eu

# The base image's auth.conf is included by the Web Player locations.
# The library already has its own Stremio-account session auth, so keep it
# outside HTTP Basic authentication or the two authentication layers collide.
for conf in /etc/nginx/http.d/default.conf /etc/nginx/https.conf; do
    [ -f "$conf" ] || continue
    if grep -q 'location = /library {' "$conf"; then
        continue
    fi

    tmp="$(mktemp)"
    awk '
        /^[[:space:]]*location \/ \{/ && !added {
            print "    # Library UI has its own Stremio-account authentication."
            print "    location = /library {"
            print "        proxy_pass http://backend;"
            print "    }"
            print ""
            print "    location ^~ /library/ {"
            print "        proxy_pass http://backend;"
            print "    }"
            print ""
            added=1
        }
        { print }
        END {
            if (!added) exit 1
        }
    ' "$conf" > "$tmp"

    mv "$tmp" "$conf"
done
