#!/usr/bin/env bash
# Push the current accent to the desk lights. Rendered by caelestia from the
# current scheme; run it yourself, nothing calls it automatically.

TOKEN_FILE="$HOME/.config/inir/homeassistant_token"
if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "Home Assistant token not found at $TOKEN_FILE" >&2
  exit 1
fi
TOKEN="$(< "$TOKEN_FILE")"

PRIMARY="{{ primary.hex }}"

R=$(printf "%d" 0x${PRIMARY:0:2})
G=$(printf "%d" 0x${PRIMARY:2:2})
B=$(printf "%d" 0x${PRIMARY:4:2})

curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  http://homeassistant.local:8123/api/services/light/turn_on \
  -d "{
    \"entity_id\": [\"light.desk_1\",\"light.desk_2\"],
    \"rgb_color\": [$R, $G, $B]
  }"
