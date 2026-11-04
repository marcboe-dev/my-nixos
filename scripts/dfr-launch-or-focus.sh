# Fokussiert das zuletzt geöffnete Fenster, dessen app-id auf das Muster passt,
# oder startet den Befehl, falls keins offen ist.
# Beispiel: dfr-launch-or-focus '^brave-browser$' brave
PATTERN="$1"
shift

ID=$(niri msg --json windows |
  jq --arg p "$PATTERN" '[.[] | select((.app_id // "") | test($p; "i"))] | last | .id // empty')

if [ -n "$ID" ]; then
  niri msg action focus-window --id "$ID"
else
  niri msg action spawn -- "$@"
fi
