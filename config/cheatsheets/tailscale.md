## !! NordVPN + Tailscale (einmalig pro Rechner, nach nordvpn login) !!
nordvpn allowlist add subnet 100.64.0.0/10      Tailnet an NordVPN vorbei
nordvpn allowlist add port 41641 protocol UDP   Tailscale-Port freigeben
nordvpn settings                                prüfen: Allowlisted Subnets / Ports
                                                bleibt gespeichert, weg nur bei Neuinstallation

## Alltag
ssh marc@nixos-server           interaktive Shell am Server
ssh marc@nixos-server 'cmd'     einzelnen Befehl am Server ausführen
tmux / tmux attach              am Server: Sitzung starten / nach Abbruch zurückholen

## Status prüfen
tailscale status                bin ich verbunden? welche Rechner sind online?
tailscale ping nixos-server     kommt überhaupt etwas an?
tailscale ip -4                 eigene Tailscale-IP (100.x.y.z)

## Verbindung
tailscale up                    verbinden (falls "Logged out" / "stopped")
tailscale down                  Tailscale kurz ausschalten
sudo tailscale login            neu anmelden

## Einrichtung neuer Rechner (einmalig)
services.tailscale.enable = true;   in hosts/<host>/default.nix eintragen
nrs                                 System neu bauen
nordvpn disconnect                  sonst hängt tailscale up
sudo tailscale up                   mit demselben Account anmelden (Link öffnen)
sudo tailscale set --operator=marc  danach tailscale-Befehle ohne sudo
nordvpn connect                     danach Allowlist oben setzen

## Server ausrollen (von VM / t14)
git add -A                      Flakes sehen nur Dateien, die Git kennt
nixos-rebuild switch --flake .#nixos-server --target-host marc@nixos-server --sudo --ask-sudo-password
ssh marc@nixos-server 'cd ~/nixos-dotfiles && git pull'    Server-Klon nachziehen

## Exit Node (Traffic über Heimanschluss)
tailscale set --exit-node=nixos-server      Exit Node einschalten
tailscale set --exit-node=                  Exit Node ausschalten
curl ifconfig.me; echo                      welche IP sehe ich gerade?

## Fehler
tailscale up hängt              NordVPN blockiert → nordvpn disconnect, erneut probieren
nixos-server nicht gefunden     ssh marc@100.x.y.z   (NordVPN-DNS, IP aus tailscale status)
Server "offline"                Problem am Server (aus, kein Netz), nicht am Client
NordVPN aktiv, nichts geht      Allowlist gesetzt? (nordvpn settings) sonst nordvpn disconnect
HOST IDENTIFICATION CHANGED     ssh-keygen -R nixos-server   (nach Neuinstallation)
Server nach Monaten weg         Key expiry in Admin-Konsole deaktivieren
