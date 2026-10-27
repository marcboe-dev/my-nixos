# ─────────────────────────────────────────────────────────────────────
# Profil: Server (headless, z.B. ein alter Laptop daheim)
#
# Ein Host bekommt dieses Profil über hosts/<n>/default.nix:
#
#     imports = [ ../../profiles/server.nix ];
#
# Kein Desktop, kein Audio, keine GUI-Apps. Home-Manager bekommt nur
# home/base.nix (bash, git, neovim, tmux, yazi) aus flake.nix.
#
# Aufgaben:
#   - Tailscale-Exit-Node: Traffic von unterwegs geht über den Heimanschluss
#   - Fernzugriff per SSH (über Tailscale oder im Heimnetz)
#   - läuft durch: Deckel zu, kein Standby
#
# Maschinenspezifisches (Wake-on-LAN-Interface, Akku-Ladegrenzen) steht
# NICHT hier, sondern in hosts/<n>/default.nix.
# ─────────────────────────────────────────────────────────────────────
{lib, ...}: let
  # Erlaubte SSH-Schlüssel: jede Datei keys/*.pub im Repo.
  # Neuen Rechner berechtigen: dessen ~/.ssh/id_ed25519.pub als
  # keys/<rechner>.pub ins Repo legen, committen, Server neu bauen.
  keyDir = ../keys;
  keyFiles =
    if builtins.pathExists keyDir
    then
      map (n: keyDir + "/${n}")
      (builtins.filter (lib.hasSuffix ".pub") (builtins.attrNames (builtins.readDir keyDir)))
    else [];
in {
  # ── Fernzugriff: SSH ─────────────────────────────────
  # Nur mit Schlüssel, kein Passwort, kein root. Port 22 ist im Heimnetz
  # offen (Notfallzugang, falls Tailscale klemmt); von außen kommt man
  # ohnehin nur über Tailscale heran.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = ["marc"];
    };
  };
  users.users.marc.openssh.authorizedKeys.keyFiles = keyFiles;

  warnings = lib.optional (keyFiles == []) ''
    profiles/server.nix: keine SSH-Schlüssel unter keys/*.pub gefunden.
    Zugang per normalem SSH ist damit nicht möglich, nur über Tailscale SSH.
  '';

  # Stabile Shell über wackelige Verbindungen (Hotel-WLAN, Handy-Hotspot).
  # Ports nicht ins Heimnetz öffnen; über Tailscale ist ohnehin alles erlaubt.
  programs.mosh = {
    enable = true;
    openFirewall = false;
  };

  # ── Tailscale als Exit Node ──────────────────────────
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server"; # IP-Forwarding für den Exit Node
    openFirewall = true; # direkte Verbindungen statt Umweg über Relays (schneller)
    # Wird bei jedem Start von tailscaled angewendet (deklarativ):
    #   --advertise-exit-node  dieser Rechner bietet sich als Exit Node an
    #   --ssh                  Tailscale SSH als zweiter Zugang (ohne Schlüssel)
    extraSetFlags = [
      "--advertise-exit-node"
      "--ssh"
    ];
  };

  # Alles, was über Tailscale kommt, ist vertrauenswürdig
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # ── Läuft durch: kein Standby ────────────────────────
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # ── Wartung & Stabilität ─────────────────────────────
  services.smartd.enable = true; # Festplatten-Gesundheit überwachen (journalctl -u smartd)
  services.journald.settings.Journal.SystemMaxUse = "500M"; # Logs nicht ausufern lassen

  # Remote-Rebuild vom Laptop aus:
  #   nixos-rebuild switch --flake .#nixos-server --target-host marc@nixos-server --sudo --ask-sudo-password
  # Dafür muss marc Pakete auf den Server kopieren dürfen.
  nix.settings.trusted-users = ["@wheel"];
}
