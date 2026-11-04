# Startet eine App und macht ihr NEUES Fenster schwebend, mit fester Größe.
# Funktioniert auch bei Single-Instance-Apps (Thunar, Brave), wo app-id-Regeln
# schwebende und normale Fenster nicht unterscheiden können.
# Beispiel: dfr-float-spawn '^thunar$' 50% 60% thunar
PATTERN="$1"
WIDTH="$2"
HEIGHT="$3"
shift 3

BEFORE=$(niri msg --json windows | jq -c '[.[].id]')

# Event-Stream VOR dem Start öffnen, damit kein Fenster verpasst wird.
exec 3< <(timeout 5 niri msg --json event-stream)
niri msg action spawn -- "$@"

ID=""
while read -r line <&3; do
  ID=$(jq -r --argjson before "$BEFORE" --arg p "$PATTERN" '
    .WindowOpenedOrChanged.window // empty
    | select((.id as $i | $before | any(.[]; . == $i)) | not)
    | select((.app_id // "") | test($p; "i"))
    | .id' <<<"$line")
  [ -n "$ID" ] && break
done
exec 3<&-

[ -z "$ID" ] && exit 0

niri msg action move-window-to-floating --id "$ID"
niri msg action set-window-width --id "$ID" "$WIDTH"
niri msg action set-window-height --id "$ID" "$HEIGHT"
