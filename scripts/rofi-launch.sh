# Startmenü: p = Projects, s = Sessions, b = Bookmarks, g = Google Drive, c = Cook
# Der Buchstabe in [] ist die Taste. "-matching prefix" matcht ab jeder
# Wortgrenze (\b), deshalb trifft "s" auch "[S]essions". Wichtig: kein
# anderes Wort darf mit demselben Buchstaben beginnen, sonst greift
# -auto-select nicht mehr.
choice="$(printf '%s\n' '[P]rojects' '[S]essions' '[B]ookmarks' '[G]oogle Drive' '[C]ook' \
  | rofi -dmenu -i -matching prefix -auto-select -no-custom -p 'Launch')" || exit 0

# Muster in Anführungszeichen: ohne wären [P] usw. Glob-Zeichenklassen
case "$choice" in
  '[P]rojects')     exec rofi-repos ;;
  '[S]essions')     exec rofi-sessions ;;
  '[B]ookmarks')    exec rofi-bookmarks ;;
  '[G]oogle Drive') exec gdrive-bisync ;;
  '[C]ook')
    # Workspace darunter, dort Brave mit den Rezeptseiten + Terminal im Rezeptordner
    niri msg action focus-workspace-down
    setsid -f brave --new-window \
      'https://cookidoo.at/created-recipes/de-AT/01M6E2499DXXHX4K8RQSPXZF4F' \
      'https://www.youtube.com/watch?v=VjSmYp2WmWA' \
      'https://www.zaubertopf-club.de/rezept/einfaches-rote-linsen-curry-thermomix.html' \
      'https://www.removepaywall.com/search?url=https://www.zaubertopf-club.de/rezept/high-protein-linsencurry-thermomix.html'\
      >/dev/null 2>&1
    # Kurz warten, damit Brave links und das Terminal rechts daneben landet
    sleep 0.5
    mkdir -p "$HOME/Documents/recipes"
    cd "$HOME/Documents/recipes"
    exec "${TERMINAL:-kitty}"
    ;;
esac
