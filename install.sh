# Nutzung: install <host> [laptop] [niri|qtile]
#   host:       Ordnername unter hosts/ (z.B. t14, t490, vm)
#   laptop:     nur nötig, wenn hosts/<host> noch nicht existiert
#               (legt einen neuen Laptop-Host mit den Daten dieser Maschine an)
#   niri|qtile: Desktop des Laptops. Bei neuen Laptops wird sonst gefragt,
#               bei bestehenden wird damit umgestellt. Die VM ist immer qtile.
#   Die Reihenfolge von "laptop" und "niri|qtile" ist egal.
#
# Beispiele:
#   install vm                  # VM, immer qtile
#   install t490 laptop         # neuer Laptop, fragt nach dem Desktop
#   install t490 laptop qtile   # neuer Laptop, direkt mit qtile
#   install t14                 # bestehender Laptop, Desktop wie in Git
#   install t14 qtile           # bestehender Laptop, auf qtile umstellen

REPO="https://github.com/marcboe-dev/my-nixos.git"
DIR="$HOME/nixos-dotfiles"

confirm() {
  read -r -p "$1 [j/N] " ANTWORT
  [ "$ANTWORT" = "j" ] || { echo "Abgebrochen."; exit 1; }
}

# ── 1. systemd-boot braucht UEFI ───────────────────────────────
if [ ! -d /sys/firmware/efi ]; then
  echo "FEHLER: System läuft nicht im UEFI-Modus. Die Config nutzt systemd-boot."
  echo "Im BIOS/UEFI auf UEFI-Boot umstellen und NixOS neu installieren."
  exit 1
fi

# ── 2. Repo holen bzw. aktualisieren ───────────────────────────
if [ -d "$DIR/.git" ]; then
  URL="$(git -C "$DIR" remote get-url origin)"
  case "$URL" in
    *marcboe-dev/my-nixos*) ;;
    *)
      echo "FEHLER: $DIR ist ein Klon eines anderen Repos ($URL)."
      echo "Löschen mit: rm -rf $DIR   und neu starten."
      exit 1
      ;;
  esac
  git -C "$DIR" pull --ff-only || echo "WARNUNG: pull fehlgeschlagen, es wird mit dem lokalen Stand gebaut."
else
  git clone "$REPO" "$DIR"
fi
cd "$DIR"

# ── 3. Argumente prüfen ────────────────────────────────────────
NAME="${1:-}"
TYP=""
DESKTOP=""

# Restliche Argumente in beliebiger Reihenfolge einsammeln
for ARG in "${@:2}"; do
  case "$ARG" in
    laptop) TYP="laptop" ;;
    niri | qtile) DESKTOP="$ARG" ;;
    *)
      echo "FEHLER: Unbekanntes Argument '$ARG' (erlaubt: laptop, niri, qtile)."
      exit 1
      ;;
  esac
done

if [ -z "$NAME" ]; then
  echo "Nutzung: install <host> [laptop] [niri|qtile]"
  echo "Bekannte Hosts:"
  for d in hosts/*/; do echo "  $(basename "$d")"; done
  exit 1
fi

if ! [[ "$NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "FEHLER: Hostname '$NAME' ungültig (nur a-z, 0-9 und Bindestrich)."
  exit 1
fi

HOSTDIR="hosts/$NAME"
HW="$HOSTDIR/hardware-configuration.nix"

# ── 4. Passt der Host zur Maschine (VM oder Bare Metal)? ───────
VIRT="$(systemd-detect-virt || true)"   # "none" auf Bare Metal
if [ "$NAME" = "vm" ] && [ "$VIRT" = "none" ]; then
  echo "WARNUNG: Host 'vm' gewählt, aber das ist keine virtuelle Maschine."
  confirm "Trotzdem fortfahren?"
fi
if [ "$NAME" != "vm" ] && [ "$VIRT" != "none" ]; then
  echo "WARNUNG: Host '$NAME' gewählt, aber das System läuft virtualisiert ($VIRT)."
  confirm "Trotzdem fortfahren?"
fi

# ── 4b. Desktop-Wahl bei der VM ignorieren ─────────────────────
# Die VM ist fest auf qtile eingestellt (hosts/vm/default.nix).
if [ "$NAME" = "vm" ] && [ -n "$DESKTOP" ]; then
  if [ "$DESKTOP" != "qtile" ]; then
    echo "HINWEIS: Die VM läuft immer mit qtile. '$DESKTOP' wird ignoriert."
  fi
  DESKTOP=""
fi

# ── 5. Neuen Laptop-Host anlegen bzw. Desktop umstellen ────────
if [ ! -f "$HOSTDIR/default.nix" ]; then
  if [ "$TYP" != "laptop" ]; then
    echo "Host '$NAME' existiert nicht unter hosts/."
    echo "Neuen Laptop anlegen mit: install $NAME laptop [niri|qtile]"
    exit 1
  fi

  # Desktop abfragen, falls nicht als Argument übergeben
  if [ -z "$DESKTOP" ]; then
    echo "Welcher Desktop für '$NAME'?"
    echo "  1) niri  (Wayland, Kitty, Standard)"
    echo "  2) qtile (X11, Alacritty)"
    read -r -p "Auswahl [1]: " WAHL
    case "${WAHL:-1}" in
      1) DESKTOP="niri" ;;
      2) DESKTOP="qtile" ;;
      *) echo "Ungültige Auswahl."; exit 1 ;;
    esac
  fi

  mkdir -p "$HOSTDIR"

  # Internes Display (EDID) dieser Maschine direkt aus /sys lesen
  EDIDFILE=""
  for f in /sys/class/drm/card*-eDP-*/edid /sys/class/drm/card*-LVDS-*/edid; do
    if [ -e "$f" ]; then EDIDFILE="$f"; break; fi
  done

  if [ -n "$EDIDFILE" ]; then
    PANEL="$(basename "$(dirname "$EDIDFILE")" | sed 's/^card[0-9]*-//')"
    EDID="$(od -An -tx1 "$EDIDFILE" | tr -d ' \n')"
  else
    PANEL="eDP-1"
    EDID=""
    echo "WARNUNG: Kein internes Display gefunden. autorandr bleibt aus,"
    echo "         bis my.laptop.edid in $HOSTDIR/default.nix gesetzt ist."
  fi

  # Ohne Anführungszeichen um EOF, damit $NAME und $DESKTOP eingesetzt werden
  # Ohne Anführungszeichen um EOF, damit $NAME, $DESKTOP, $PANEL und $EDID eingesetzt werden
  cat > "$HOSTDIR/default.nix" <<EOF
{...}: {
  imports = [./hardware-configuration.nix];

  # Desktop dieses Laptops: "niri" (Wayland, Kitty) oder "qtile" (X11, Alacritty).
  # Ändern: hier umstellen ODER  install $NAME niri|qtile  erneut ausführen.
  my.desktop = "$DESKTOP";

  # Laptop-Teile einschalten, Werte dieser Maschine (von install.sh ausgelesen)
  my.laptop = {
    enable = true;
    panel = "$PANEL";
    edid = "$EDID";
    speakerCard = null; # optional: Name aus  pactl list cards short
    dpi = 120; # nur qtile: 96 = 100 %, 120 = 125 %, 144 = 150 %
  };
}
EOF

  echo "Neuer Laptop-Host '$NAME' mit Desktop '$DESKTOP' angelegt."

elif [ -n "$DESKTOP" ]; then
  # Bestehender Laptop + Desktop als Argument → Zeile in default.nix umstellen
  if grep -q '^  my.desktop = ' "$HOSTDIR/default.nix"; then
    sed -i "s/^  my.desktop = .*/  my.desktop = \"$DESKTOP\";/" "$HOSTDIR/default.nix"
    echo "Desktop von '$NAME' auf $DESKTOP gesetzt."
  else
    echo "FEHLER: In $HOSTDIR/default.nix fehlt die Zeile:  my.desktop = \"...\";"
    echo "Bitte einmal von Hand eintragen (siehe hosts/t14/default.nix)."
    exit 1
  fi
fi

# ── 6. Hardware-Config dieser Maschine übernehmen ──────────────
# Bei der VM ist ein Unterschied normal (jede VM hat neue UUIDs), daher keine Rückfrage.
if [ "$NAME" != "vm" ] && [ -f "$HW" ] && ! cmp -s /etc/nixos/hardware-configuration.nix "$HW"; then
  echo "ACHTUNG: Die Hardware-Config von '$NAME' weicht von dieser Maschine ab."
  echo "Normal bei einer Neuinstallation DERSELBEN Maschine."
  echo "FALSCH, wenn das eine andere Maschine ist (dann bootet der andere Rechner nicht mehr)."
  confirm "Hardware-Config von '$NAME' ersetzen?"
fi
cp /etc/nixos/hardware-configuration.nix "$HW"

# Flakes sehen nur Dateien, die Git kennt
git add -A "$HOSTDIR"

# ── 7. System bauen ────────────────────────────────────────────
sudo nixos-rebuild switch --flake ".#nixos-$NAME" --option experimental-features "nix-command flakes"

# ── 8. Hinweis zum Sichern ─────────────────────────────────────
echo
if [ "$NAME" = "vm" ]; then
  echo "Fertig. Für die VM ist kein Commit nötig."
elif [ -n "$(git status --porcelain -- "$HOSTDIR")" ]; then
  echo "Fertig. Es gibt Änderungen an hosts/$NAME (neuer Host, neue Hardware-Config oder neuer Desktop)."
  echo "Nach dem Neustart im Repo sichern:"
  echo "  gh auth login"
  echo "  cd ~/nixos-dotfiles && git commit -m \"Host $NAME\" && git push"
else
  echo "Fertig. Nichts zu committen."
fi
