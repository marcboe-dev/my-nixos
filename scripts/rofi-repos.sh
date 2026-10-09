# Projekt aus ~/repos wählen -> tmux-Session dort öffnen oder anhängen
repos_dir="${REPOS_DIR:-$HOME/repos}"
terminal="${TERMINAL:-alacritty}"
one_terminal="${ONE_TERMINAL:-1}"   # 1 = Tony-Verhalten: altes Terminal schließen

[ -d "$repos_dir" ] || exit 0

chosen="$(find "$repos_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
  | sort \
  | rofi -dmenu -i -matching fuzzy -no-custom -p 'Projects')" || exit 0
[ -n "$chosen" ] || exit 0

dir="$repos_dir/$chosen"
# tmux erlaubt keine . und : in Session-Namen
session="$(printf '%s' "$chosen" | tr '.:' '__')"

# Aufruf aus tmux heraus: nur Session wechseln
if [ -n "${TMUX:-}" ]; then
  tmux has-session -t "=$session" 2>/dev/null \
    || tmux new-session -ds "$session" -c "$dir"
  exec tmux switch-client -t "=$session"
fi

if [ "$one_terminal" = 1 ]; then
  pkill -x "$terminal" 2>/dev/null || true
  sleep 0.1
fi

exec "$terminal" -e tmux new-session -A -s "$session" -c "$dir"
