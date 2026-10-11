# NixOS-Konfiguration

Hosts: `nixos-laptop` (Bare Metal), `nixos-vm` (VMware Workstation Pro)

## Neuinstallation

1. NixOS mit dem grafischen Installer installieren
   - Benutzer: `marc`
   - Laptop im UEFI-Modus booten
   - Desktop egal, wird durch die Config ersetzt
2. Nach dem ersten Login mit dem Internet verbinden und ausführen:

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/my-nixos --refresh -- nixos-laptop

   Für die VM statt `nixos-laptop` einfach `nixos-vm`.
3. Neu starten und beim Login die Qtile-Sitzung wählen.

Das Skript klont das Repo nach `~/nixos-dotfiles`, übernimmt die
Hardware-Config der Maschine und baut das System inkl. Home Manager.

## Danach (optional)

    gh auth login
    cd ~/nixos-dotfiles
    git commit -m "Hardware-Config <host>"
    git push

## Manueller Fallback (falls das Skript nicht läuft)

    nix-shell -p git
    git clone https://github.com/marcboe-dev/my-nixos.git ~/nixos-dotfiles
    cd ~/nixos-dotfiles
    cp /etc/nixos/hardware-configuration.nix hosts/laptop/   # VM: hosts/vm/
    git add .
    sudo nixos-rebuild switch --flake .#nixos-laptop --option experimental-features "nix-command flakes"

## Im Alltag

    nrs                    # System neu bauen
    nix flake update       # Pakete aktualisieren, danach nrs

Wichtig: Das Repo muss in `~/nixos-dotfiles` liegen, sonst fehlen
Dotfiles und Hintergrundbild.
