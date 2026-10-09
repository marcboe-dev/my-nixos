# Bestehende tmux-Sessions auflisten, anhängen oder neue anlegen
terminal="${TERMINAL:-alacritty}"
one_terminal="${ONE_TERMINAL:-1}"
new_entry="+ Neue Session…"

sessions="$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)"

# Kein -no-custom: eigener Text ist erlaubt (neue Session direkt per Name)
choice="$(printf '%s\n%s\n' "$new_entry" "$sessions" \
  | sed '/^$/d' \
  | rofi -dmenu -i -matching fuzzy -p 'tmux')" || exit 0
[ -n "$choice" ] || exit 0

if [ "$choice" = "$new_entry" ]; then
  choice="$(rofi -dmenu -p 'Neue Session' < /dev/null)" || exit 0
  [ -n "$choice" ] || exit 0
fi

session="$(printf '%s' "$choice" | tr '.:' '__')"

if [ -n "${TMUX:-}" ]; then
  tmux has-session -t "=$session" 2>/dev/null \
    || tmux new-session -ds "$session"
  exec tmux switch-client -t "=$session"
fi

if [ "$one_terminal" = 1 ]; then
  pkill -x "$terminal" 2>/dev/null || true
  sleep 0.1
fi

exec "$terminal" -e tmux new-session -A -s "$session"
