#!/usr/bin/env bash
# Bildwiederholrate des externen Bildschirms (Fernseher) durchschalten:
# 60 Hz → 24 Hz → 50 Hz → 60 Hz
#   60 Hz: Standard, YouTube mit 30/60 fps
#   24 Hz: Kinofilme und Serien (24 fps)
#   50 Hz: europäisches Material (25/50 fps)
# Aufruf über niri: Mod+Alt+T → spawn "tv-hz"

notify() {
    notify-send -a "Fernseher" \
        -h string:x-canonical-private-synchronous:tv-hz \
        "Fernseher" "$1"
}

outputs="$(niri msg -j outputs)"

# Erster eingeschalteter Bildschirm, der nicht das Laptop-Display ist
out="$(jq -r '
    to_entries[]
    | select((.key | startswith("eDP")) | not)
    | select(.value.current_mode != null)
    | .key
' <<<"$outputs" | head -n1)"

if [[ -z "$out" ]]; then
    notify "Kein externer Bildschirm angeschlossen"
    exit 0
fi

# Aktuelle Rate in ganzen Hz (niri liefert Millihertz, z. B. 59940)
hz="$(jq -r --arg o "$out" '
    .[$o] | .modes[.current_mode].refresh_rate / 1000 | round
' <<<"$outputs")"

case "$hz" in
    60) next=24; label="24 Hz · Filme (24 fps)" ;;
    24) next=50; label="50 Hz · Europa (25/50 fps)" ;;
    *)  next=60; label="60 Hz · Standard (30/60 fps)" ;;
esac

# Passenden Modus mit gleicher Auflösung suchen
mode="$(jq -r --arg o "$out" --argjson hz "$next" '
    .[$o]
    | .modes[.current_mode] as $c
    | .modes
    | map(select(
        .width == $c.width and .height == $c.height
        and ((.refresh_rate / 1000 | round) == $hz)
      ))
    | first
    | if . == null then empty
      else "\(.width)x\(.height)@\(.refresh_rate / 1000)" end
' <<<"$outputs")"

if [[ -z "$mode" ]]; then
    notify "$next Hz wird von $out nicht unterstützt"
    exit 1
fi

niri msg output "$out" mode "$mode"
notify "$label"
