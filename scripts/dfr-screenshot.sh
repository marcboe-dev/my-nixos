#!/usr/bin/env bash
# Take a screenshot in a number of different ways. Any of the case statement
# options can be passed in as a value.

set -o errexit
set -o pipefail
set -o nounset

MODE="${1:-region}"

shot="$(mktemp --suffix=.png)"
trap 'rm -f "$shot"' EXIT

case "${MODE}" in
region)
  grim -g "$(slurp -d)" "$shot"
  ;;
window)
  niri msg action screenshot-window
  sleep 0.5
  wl-paste --type image/png >"$shot"
  ;;
monitor-focused)
  grim -o "$(niri msg --json focused-output | jq --raw-output .name)" "$shot"
  ;;
monitor-all)
  grim "$shot"
  ;;
*)
  echo "'${MODE}' is not a supported, aborting!" >&2
  exit 1
  ;;
esac

# rofi ist eine Overlay-Layer-Surface: liegt über allen Fenstern und hält
# den Tastaturfokus. Erst NACH der Aufnahme schließen (damit es mit aufs
# Bild kommt), aber VOR satty, damit man das Bild bearbeiten kann.
pkill -x rofi || true

satty --filename "$shot" \
  --output-filename "${XDG_PICTURES_DIR:-$HOME/Pictures}/screenshot-%+.png"
