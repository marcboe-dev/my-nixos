# Bookmarks: [personal] -> Firefox, [work] -> Brave
pers_file="${PERS_FILE:-$HOME/.config/bookmarks/personal.txt}"
work_file="${WORK_FILE:-$HOME/.config/bookmarks/work.txt}"
personal_browser="${PERSONAL_BROWSER:-firefox}"
work_browser="${WORK_BROWSER:-brave}"

mkdir -p "$(dirname "$pers_file")" "$(dirname "$work_file")"
[ -f "$pers_file" ] || printf '# personal\nNixOS Search :: https://search.nixos.org\n' > "$pers_file"
[ -f "$work_file" ] || printf '# work\nNixOS Manual :: https://nixos.org/manual/\n' > "$work_file"

# Format pro Zeile: "Label :: URL" oder nur "URL"
emit() {
  local tag="$1" file="$2" line label url
  { grep -vE '^[[:space:]]*(#|$)' "$file" || true; } | while IFS= read -r line; do
    if [[ "$line" == *"::"* ]]; then
      label="${line%%::*}"; url="${line#*::}"
    else
      label="$line"; url="$line"
    fi
    label="$(printf '%s' "$label" | sed 's/[[:space:]]*$//')"
    url="$(printf '%s' "$url" | sed 's/^[[:space:]]*//')"
    printf '[%s] %s :: %s\n' "$tag" "$label" "$url"
  done
}

choice="$({ emit personal "$pers_file"; emit work "$work_file"; } \
  | sort \
  | rofi -dmenu -i -matching fuzzy -p 'Bookmarks')" || exit 0
[ -n "$choice" ] || exit 0

tag="${choice#\[}"; tag="${tag%%]*}"
url="${choice##* :: }"

case "$url" in
  http://*|https://*|file://*|about:*) ;;
  *) url="https://$url" ;;
esac

case "$tag" in
  work) browser="$work_browser" ;;
  *)    browser="$personal_browser" ;;
esac

if command -v "$browser" >/dev/null 2>&1; then
  setsid -f "$browser" "$url" >/dev/null 2>&1
else
  setsid -f xdg-open "$url" >/dev/null 2>&1
fi
