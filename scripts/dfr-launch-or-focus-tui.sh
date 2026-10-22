# Startet ein TUI in Kitty mit eigener app-id (dfr.kitty.<app>)
# oder fokussiert es, falls es schon läuft.
# Beispiel: dfr-launch-or-focus-tui btop
APP="$1"
shift
CLASS="dfr.kitty.${APP}"

ID=$(niri msg --json windows |
  jq --arg c "$CLASS" '[.[] | select(.app_id == $c)] | last | .id // empty')

if [ -n "$ID" ]; then
  niri msg action focus-window --id "$ID"
else
  if ! command -v "$APP" >/dev/null 2>&1; then
    echo "$APP existiert nicht, Abbruch!" >&2
    exit 1
  fi
  niri msg action spawn -- kitty --class "$CLASS" -e "$APP" "$@"
fi
