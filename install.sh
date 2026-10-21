# Nutzung: install <host> [laptop]
#   host:   Ordnername unter hosts/ (z.B. t14, t490, vm)
#   laptop: nur nötig, wenn hosts/<host> noch nicht existiert
#           (legt einen neuen Laptop-Host mit den Daten dieser Maschine an)

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
TYP="${2:-}"

if [ -z "$NAME" ]; then
  echo "Nutzung: install <host> [laptop]"
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

# ── 5. Neuen Laptop-Host anlegen ───────────────────────────────
if [ ! -f "$HOSTDIR/default.nix" ]; then
  if [ "$TYP" != "laptop" ]; then
    echo "Host '$NAME' existiert nicht unter hosts/."
    echo "Neuen Laptop anlegen mit: install $NAME laptop"
    exit 1
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
    echo "         bis edidLaptop in $HOSTDIR/machine.nix gesetzt ist."
  fi

  cat > "$HOSTDIR/default.nix" <<'EOF'
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../laptop-common.nix (import ./machine.nix))
  ];
}
EOF

  cat > "$HOSTDIR/machine.nix" <<EOF
{
  panel = "$PANEL";
  edidLaptop = "$EDID";
  speakerCard = null; # optional: Soundkarten-Name aus pactl list cards short
}
EOF

  echo "Neuer Laptop-Host '$NAME' angelegt."
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
  echo "Fertig. Es gibt Änderungen an hosts/$NAME (neuer Host oder neue Hardware-Config)."
  echo "Nach dem Neustart im Repo sichern:"
  echo "  gh auth login"
  echo "  cd ~/nixos-dotfiles && git commit -m \"Host $NAME\" && git push"
else
  echo "Fertig. Nichts zu committen."
fi
