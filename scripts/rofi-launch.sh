# Startmenü: p = Projects, s = Sessions, b = Bookmarks
choice="$(printf '%s\n' Projects Sessions Bookmarks \
  | rofi -dmenu -i -matching prefix -auto-select -no-custom -p 'Launch')" || exit 0

case "$choice" in
  Projects)  exec rofi-repos ;;
  Sessions)  exec rofi-sessions ;;
  Bookmarks) exec rofi-bookmarks ;;
esac
