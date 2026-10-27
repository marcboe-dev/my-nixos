# ─────────────────────────────────────────────────────────────────────
# Laptop-Teile (für alle Hosts mit  my.laptop.enable = true;)
#
# Definiert die Option `my.laptop`. Ein Laptop setzt sie in
# hosts/<n>/default.nix, z.B.:
#
#     my.laptop = {
#       enable = true;
#       panel = "eDP-1";
#       edid = "00ff…";
#     };
#
# Die VM setzt nichts → enable ist false → alles hier bleibt aus.
#
# Desktop-spezifisch:
#   qtile: zusätzlich ./qtile.nix (autorandr, picom, Touchpad, DPI, dunst)
#   niri:  kein Zusatz nötig. Monitore, Touchpad und Skalierung stehen in
#          config/niri/config.kdl, Benachrichtigungen macht noctalia.
# ─────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.laptop;

  # Dock: gleich für jeden Laptop an deinem Dock
  dockId = "cf030000-0080-7718-a350-5310d8304021"; # cat /sys/bus/thunderbolt/devices/1-1/unique_id

  batteryNotify = pkgs.writeShellApplication {
    name = "battery-notify";
    runtimeInputs = [pkgs.libnotify pkgs.coreutils];
    text = builtins.readFile ../../scripts/battery_notify.sh;
  };

  tvHz = pkgs.writeShellApplication {
    name = "tv-hz";
    runtimeInputs = [pkgs.jq pkgs.libnotify pkgs.coreutils];
    text = builtins.readFile ../../scripts/tv_hz.sh;
  };
in {
  # imports dürfen nie in lib.mkIf stehen, qtile.nix prüft selbst
  imports = [./qtile.nix];

  options.my.laptop = {
    enable = lib.mkEnableOption "Laptop-Teile (Dock, Akku, Bluetooth, NordVPN …)";

    panel = lib.mkOption {
      type = lib.types.str;
      default = "eDP-1";
      description = "Name des internen Displays (für autorandr unter qtile).";
    };

    edid = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "EDID des internen Displays. Leer = autorandr bleibt aus.";
    };

    speakerCard = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Soundkarte für das Lautsprecher-Profil (pactl list cards short).";
    };

    dpi = lib.mkOption {
      type = lib.types.int;
      default = 120;
      description = "Nur qtile: 96 = 100 %, 120 = 125 %, 144 = 150 %.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Firmware-Updates für BIOS, Dock, Thunderbolt (fwupdmgr)
    services.fwupd.enable = true;

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
      pkgs.pavucontrol # grafischer Audio-Manager
      pkgs.brightnessctl
      pkgs.overskride # grafischer Bluetooth-Manager
      pkgs.nordvpn
      pkgs.libnotify
      tvHz # Fernseher-Hz durchschalten (Mod+Alt+T)
      pkgs.wdisplays # grafische Bildschirm-Anordnung (temporär, Feste Werte in niri config.kdl)
      pkgs.gnome-disk-utility # „Laufwerke“: USB-Sticks formatieren/partitionieren
    ];

    # Soundprofil mit Laptop-Lautsprechern (nur wenn speakerCard gesetzt)
    services.pipewire.wireplumber.extraConfig = lib.mkIf (cfg.speakerCard != null) {
      "51-laptop-speaker" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {"device.name" = cfg.speakerCard;}
            ];
            actions.update-props = {
              "device.profile" = "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)";
            };
          }
        ];
      };
    };

    # Akkustatus für Bar-Widget und `upower -i`
    services.upower.enable = true;

    # Hardware-Videobeschleunigung (Intel, VA-API) für Brave/YouTube
    hardware.graphics = {
      enable = true;
      extraPackages = [pkgs.intel-media-driver];
    };
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # NordVPN-Dienst
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

    # Benachrichtigung bei niedrigem Akku (qtile)
    # Unter niri warnt noctalia selbst (config/noctalia/config.toml → [battery]).
    systemd.user.services.battery-notify = lib.mkIf (config.my.desktop == "qtile") {
      description = "Battery notifications at 20% and 10%";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = lib.getExe batteryNotify;
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
