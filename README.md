# NixOS-Konfiguration

Reproduzierbares NixOS mit Flakes und Home Manager für Bare Metal
(ThinkPads) und VMware Workstation Pro.

## Struktur

    flake.nix                 # Hosts werden automatisch aus hosts/ erzeugt
    configuration.nix         # gemeinsame System-Config
    hosts/
      t14/           # eine Maschine = ein Ordner
        default.nix           # Desktop + Laptop-Werte (EDID, Soundkarte, DPI)
        hardware-configuration.nix
      t490/          # wird beim ersten Install automatisch angelegt
      vm/
    system/                   # NixOS-Ebene
      desktop/                # my.desktop: niri oder qtile
      laptop/                 # my.laptop: Dock, Akku, Bluetooth, autorandr ...
      terminal.nix            # my.terminal: folgt dem Desktop
    home/                     # Home-Manager-Ebene
      home.nix, desktop.nix
      apps/                   # GUI-Programme
      cli/                    # Terminal-Tools
    config/                   # Dotfiles (nvim, qtile, tmux, rofi, ...)
    scripts/

Der Hostname jeder Maschine ist `nixos-<ordnername>`
(`hosts/t14` → `nixos-t14`).

## Neu installieren (egal was)

1. NixOS mit dem grafischen Installer installieren
   - Benutzer: `marc`
   - Im UEFI-Modus booten (`ls /sys/firmware/efi` muss existieren)
   - Desktop egal, wird durch die Config ersetzt
2. Nach dem ersten Login mit Internet verbinden und **einen** der Befehle ausführen:

   **ThinkPad T14** (bekannte Maschine):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- t14

   **VMware-VM:**

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- vm

   **ThinkPad T490, erste Installation** (legt `hosts/t490/` an):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- t490 laptop

   **ThinkPad T490, spätere Neuinstallation** (Ordner existiert bereits):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- t490

   **Neuer, anderer Laptop:** wie beim T490, nur mit eigenem Namen
   (`-- <name> laptop`, nur a–z, 0–9 und `-`).

3. Neu starten und beim Login die Qtile-Sitzung wählen.

Das Skript klont das Repo nach `~/nixos-dotfiles` (oder aktualisiert es),
übernimmt die Hardware-Config dieser Maschine und baut das System inkl.
Home Manager.

### Rückfrage zur Hardware-Config

Bei Neuinstallation **derselben** Maschine hat das System neue UUIDs. Das
Skript fragt dann, ob die Hardware-Config ersetzt werden soll → `j`.
Kommt die Frage auf einer **anderen** Maschine, antworte `N`: Du hast den
falschen Host gewählt, die Maschine würde sonst nicht mehr booten.

### Danach im Repo sichern

Nach einem neuen Laptop oder einer Neuinstallation (neue UUIDs) die
Änderungen pushen. Die VM braucht das nicht.

    gh auth login
    cd ~/nixos-dotfiles
    git commit -m "Host <name>"
    git push

## Manuelle Schritte nach der Installation

- Google Drive (rclone-Login): siehe `home/apps/google-drive_README.md`
- Brave-Sync, Bitwarden, NordVPN, Signal: jeweils anmelden

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
- Neovim-Plugins werden beim ersten Start geklont und sind noch nicht
  gepinnt (siehe Hinweise zur Reproduzierbarkeit).
