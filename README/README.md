# NixOS-Konfiguration

Reproduzierbares NixOS mit Flakes und Home Manager für Bare Metal
(ThinkPads), VMware Workstation Pro und einen Heimserver (Tailscale-Exit-Node).

## Struktur

    flake.nix                 # Hosts werden automatisch aus hosts/ erzeugt
    install.sh                # Installationsskript (über nix run)
    profiles/                 # WAS für ein Rechner (Rolle)
      base.nix                # jeder Rechner (kommt aus flake.nix)
      workstation.nix         # Desktop, Audio, GUI-Apps (+ home/workstation.nix)
      server.nix              # headless: SSH, Tailscale-Exit-Node, kein Standby
    hosts/                    # eine Maschine = ein Ordner, wählt ihr Profil
      t14/
        default.nix           # Profil + Desktop + Laptop-Werte (EDID, Soundkarte, DPI)
        hardware-configuration.nix
      t490/  vm/  server/     # werden beim ersten Install automatisch angelegt
    system/                   # NixOS-Teile der Workstation
      desktop/                # my.desktop: niri oder qtile
      laptop/                 # my.laptop: Dock, Akku, Bluetooth, autorandr ...
      terminal.nix            # my.terminal: folgt dem Desktop
    home/                     # Home-Manager-Ebene
      base.nix                # jeder Rechner: cli/ + nvim/tmux-Links
      workstation.nix         # nur Workstation: desktop/, apps/, rmpc
      desktop/                # niri.nix, qtile.nix (folgen my.desktop)
      apps/                   # GUI-Programme
      cli/                    # Terminal-Tools (auch auf dem Server)
    keys/                     # *.pub = SSH-Schlüssel, die auf den Server dürfen
    config/                   # Dotfiles (nvim, qtile, niri, tmux, rofi, ...)
    scripts/

### Rollen: Profile statt Bedingungen

Ein Host wählt seine Rolle in `hosts/<n>/default.nix` per Import:

    imports = [ ./hardware-configuration.nix ../../profiles/workstation.nix ];
    imports = [ ./hardware-configuration.nix ../../profiles/server.nix ];

Faustregel: **Imports** entscheiden, *was für ein Rechner* es ist.
**Optionen** (`my.desktop`, `my.terminal`, `my.laptop`) entscheiden, *welche
Variante* bzw. *welche Werte* – sie gibt es nur auf Workstations.
Ein neues App-Modul in `home/apps/` landet so automatisch nur auf
Workstations, nie auf dem Server.

Der Hostname jeder Maschine ist `nixos-<ordnername>`
(`hosts/t14` → `nixos-t14`).

## Desktop und Terminal

Jeder Host wählt seinen Desktop mit `my.desktop` in `hosts/<name>/default.nix`.
Das Terminal folgt automatisch:

| Desktop | Grafik  | Terminal  |
|---------|---------|-----------|
| niri    | Wayland | Kitty     |
| qtile   | X11     | Alacritty |

Die VM läuft immer mit qtile. Installiert wird nur das passende Terminal.
Abweichen pro Host mit `my.terminal = "kitty";` bzw. `"alacritty"`.

## Neu installieren (egal was)

1. NixOS mit dem grafischen Installer installieren
   - Benutzer: `marc`
   - Im UEFI-Modus booten (`ls /sys/firmware/efi` muss existieren)
   - Desktop egal, wird durch die Config ersetzt
2. Nach dem ersten Login mit Internet verbinden und **einen** der Befehle ausführen:

   **ThinkPad T14** (bekannte Maschine, Desktop wie in Git):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- t14

   **VMware-VM** (immer qtile):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- vm

   **Neuer Laptop, erste Installation** (legt `hosts/<name>/` an, fragt nach dem Desktop):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- t490 laptop

   **Neuer Server** (headless, Tailscale-Exit-Node, SSH; legt `hosts/<n>/` an):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- server server

   Das Skript erkennt Kabel-Netzwerkkarte (Wake-on-LAN) und Akku-Ladegrenze
   selbst, baut das System und startet die Tailscale-Anmeldung (Link öffnen,
   bestätigen). Danach in der Tailscale-Admin-Konsole beim Server
   „Use as exit node“ freigeben und „Disable key expiry“ setzen.

   Desktop direkt mitgeben statt Rückfrage:

       ... -- t490 laptop niri     # Wayland + Kitty
       ... -- t490 laptop qtile    # X11 + Alacritty

   **Bekannter Laptop, Neuinstallation** (Ordner existiert bereits, Desktop wie in Git):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- t490

   **Desktop eines bekannten Laptops umstellen:**

       ... -- t14 qtile

   Der Name ist frei wählbar (nur a–z, 0–9 und `-`). `laptop` braucht es nur
   beim ersten Mal, die Reihenfolge von `laptop` und `niri|qtile` ist egal.

3. Neu starten und beim Login die Sitzung des Hosts wählen
   (niri oder qtile, die VM ist immer qtile).

Das Skript klont das Repo nach `~/nixos-dotfiles` (oder aktualisiert es),
übernimmt die Hardware-Config dieser Maschine und baut das System inkl.
Home Manager. Bei einem neuen Laptop liest es das interne Display (EDID)
aus und schreibt es mit dem Desktop in `hosts/<name>/default.nix`.

### Rückfrage zur Hardware-Config

Bei Neuinstallation **derselben** Maschine hat das System neue UUIDs. Das
Skript fragt dann, ob die Hardware-Config ersetzt werden soll → `j`.
Kommt die Frage auf einer **anderen** Maschine, antworte `N`: Du hast den
falschen Host gewählt, die Maschine würde sonst nicht mehr booten.

### Danach im Repo sichern

Nach einem neuen Laptop, einer Neuinstallation (neue UUIDs) oder einem
Desktop-Wechsel die Änderungen pushen. Die VM braucht das nicht.

    gh auth login
    cd ~/nixos-dotfiles
    git commit -m "Host <name>"
    git push

## Server

- Zugang von unterwegs: `ssh marc@nixos-server` (über Tailscale) oder
  `mosh marc@nixos-server` bei wackeliger Verbindung.
- SSH-Schlüssel berechtigen: `~/.ssh/id_ed25519.pub` des Laptops als
  `keys/<laptop>.pub` ins Repo legen, committen, Server neu bauen. Bis dahin
  geht nur Tailscale SSH.
- Vom Laptop aus neu bauen, ohne am Server zu sitzen:

      nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-server \
        --target-host marc@nixos-server --sudo --ask-sudo-password

- Ausschalten: `ssh marc@nixos-server sudo systemctl poweroff`.
  Einschalten: Wake-on-LAN (im BIOS aktivieren, nur per Kabel) oder
  BIOS-Option „Power On with AC Attach“ + smarte Steckdose.
- Updates bewusst manuell, besonders vor Reisen: auf `nixos-unstable`
  kann ein Update etwas kaputt machen, während du nicht vor Ort bist.

## Manuelle Schritte nach der Installation

- Google Drive: noch nicht in der Config (TODO)
- NordVPN: siehe `nord-vpn.README.md`
- Brave-Sync, Bitwarden, Signal: jeweils anmelden

## Manueller Fallback (falls das Skript nicht läuft)

    nix-shell -p git
    git clone https://github.com/marcboe-dev/my-nixos.git ~/nixos-dotfiles
    cd ~/nixos-dotfiles
    cp /etc/nixos/hardware-configuration.nix hosts/<host>/   # <host> existiert bereits
    git add .
    sudo nixos-rebuild switch --flake .#nixos-<host> --option experimental-features "nix-command flakes"

## Im Alltag

    nrs                    # System neu bauen
    nix flake update       # Pakete aktualisieren, danach nrs

## Regeln

- Das Repo muss in `~/nixos-dotfiles` liegen, sonst fehlen Dotfiles und
  Hintergrundbild.
- Jede physische Maschine hat einen eigenen Ordner mit eigener
  `hardware-configuration.nix`. Nie die einer anderen Maschine übernehmen.
- Dock- und Monitor-Daten stehen einmal in `system/laptop/`. Nur das
  interne Display (`my.laptop.edid`) steht pro Maschine in
  `hosts/<name>/default.nix`.
- Neue Dateien vor dem Bauen mit `git add` bekannt machen, sonst sieht
  der Flake sie nicht.

## Hinweise zur Reproduzierbarkeit

- Systempakete und Home Manager sind über `flake.lock` gepinnt.
- Neovim-Plugins klont der Plugin-Manager beim ersten Start von GitHub,
  ihre Versionen sind (noch) nicht gepinnt.
