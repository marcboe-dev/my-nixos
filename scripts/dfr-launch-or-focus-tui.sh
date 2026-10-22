# Startet ein TUI in Alacritty mit eigener app-id (dfr.alacritty.<app>)
# oder fokussiert es, falls es schon läuft.
# Beispiel: dfr-launch-or-focus-tui btop
APP="$1"
shift
CLASS="dfr.alacritty.${APP}"

ID=$(niri msg --json windows |
  jq --arg c "$CLASS" '[.[] | select(.app_id == $c)] | last | .id // empty')

if [ -n "$ID" ]; then
  niri msg action focus-window --id "$ID"
else
  if ! command -v "$APP" >/dev/null 2>&1; then
    echo "$APP existiert nicht, Abbruch!" >&2
    exit 1
  fi
  niri msg action spawn -- alacritty --class "$CLASS" -e "$APP" "$@"
fi
