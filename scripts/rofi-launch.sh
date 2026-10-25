# Startmenü: p = Projects, s = Sessions, b = Bookmarks, g = Google Drive
# Der Buchstabe in [] ist die Taste. "-matching prefix" matcht ab jeder
# Wortgrenze (\b), deshalb trifft "s" auch "[S]essions". Wichtig: kein
# anderes Wort darf mit demselben Buchstaben beginnen, sonst greift
# -auto-select nicht mehr.
choice="$(printf '%s\n' '[P]rojects' '[S]essions' '[B]ookmarks' '[G]oogle Drive' \
  | rofi -dmenu -i -matching prefix -auto-select -no-custom -p 'Launch')" || exit 0

# Muster in Anführungszeichen: ohne wären [P] usw. Glob-Zeichenklassen
case "$choice" in
  '[P]rojects')     exec rofi-repos ;;
  '[S]essions')     exec rofi-sessions ;;
  '[B]ookmarks')    exec rofi-bookmarks ;;
  '[G]oogleDrive') exec gdrive-bisync ;;
esac
