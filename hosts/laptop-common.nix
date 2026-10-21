# Gemeinsame Konfiguration für alle Laptops.
# Aufruf: (import ../laptop-common.nix (import ./machine.nix))
machine: {
  pkgs,
  lib,
  ...
}: let
  # ── Dock und Monitore: gleich für jeden Laptop an deinem Dock ───
  dockId = "cf030000-0080-7718-a350-5310d8304021"; # cat /sys/bus/thunderbolt/devices/1-1/unique_id

  # ── Pro Maschine aus machine.nix ────────────────────────────────
  panel = machine.panel or "eDP-1";
  edidLaptop = machine.edidLaptop or "";
  speaker = machine.speakerCard or null;
  dpi = machine.dpi or 120;
  hasPanel = edidLaptop != ""; # ohne EDID bleibt autorandr aus

  batteryNotify = pkgs.writeShellApplication {
    name = "battery-notify";
    runtimeInputs = [pkgs.libnotify pkgs.coreutils];
    text = builtins.readFile ../scripts/battery_notify.sh;
  };
in {
  # ThinkPad Thunderbolt 3 Dock automatisch freigeben
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{unique_id}=="${dockId}", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';

  # Zuklappen: mit Monitor nichts tun, ohne Monitor Standby
  services.logind.settings.Login = {
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
  };

  environment.systemPackages = [
    pkgs.pavucontrol #grafischer Audio-Manager
    pkgs.brightnessctl
    pkgs.overskride #grafischer Bluetooth-Manager
    pkgs.nordvpn
    pkgs.libnotify
  ];

  # Soundprofil mit Laptop-Lautsprechern (nur wenn speakerCard in machine.nix gesetzt)
  services.pipewire.wireplumber.extraConfig = lib.mkIf (speaker != null) {
    "51-laptop-speaker" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {"device.name" = speaker;}
          ];
          actions.update-props = {
            "device.profile" = "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)";
          };
        }
      ];
    };
  };

  # Bluetooth + grafischer Manager (Blueman)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Nordvpn Einstellungen
  systemd.services.nordvpnd = {
    description = "NordVPN daemon";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      ExecStart = "${pkgs.nordvpn}/bin/nordvpnd";
      Restart = "on-failure";

      User = "root";
      Group = "nordvpn";

      RuntimeDirectory = "nordvpn";
      RuntimeDirectoryMode = "0770";
    };
  };

  # Notification for low battery
  systemd.user.services.battery-notify = {
    description = "Battery notifications at 20% and 10%";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = lib.getExe batteryNotify;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
