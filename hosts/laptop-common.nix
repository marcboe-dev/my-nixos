# Gemeinsame Konfiguration für alle Laptops.
# Aufruf: (import ../laptop-common.nix (import ./machine.nix))
machine: {
  pkgs,
  lib,
  ...
}: let
  # ── Dock und Monitore: gleich für jeden Laptop an deinem Dock ───
  dockId = "cf030000-0080-7718-a350-5310d8304021"; # cat /sys/bus/thunderbolt/devices/1-1/unique_id
  edidMonitor = "00ffffffffffff0030aecd62000000002b1f0104a5351f783a0565a756529c270f5054afef00714f8180818a9500a9c0a9cfb300d1cf023a801871382d40582c45000f282100001e000000fd00324c1e5512000a202020202020000000fc005432346d2d32300a2020202020000000ff00563930385a5050300a2020202001a3020318f14b901f04130302121101051423090f0783010000023a801871382d40582c45000f282100001e011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f282100001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000df"; # autorandr --fingerprint → DP-3-2
  edidMonitorHdmi = "00ffffffffffff0030aecd62000000002b1f010380351f782a0565a756529c270f5054afef00714f8180818a9500a9c0a9cfb300d1cf023a801871382d40582c45000f282100001e000000fc005432346d2d32300a2020202020000000fd00324c1e5512000a202020202020000000ff00563930385a5050300a2020202001d902031ef14b9005040302011f1213141123090f078301000065030c001000023a801871382d40582c45000f282100001e011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f28210000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000055"; # autorandr --fingerprint → HDMI-1

  # ── Pro Maschine aus machine.nix ────────────────────────────────
  panel = machine.panel or "eDP-1";
  edidLaptop = machine.edidLaptop or "";
  speaker = machine.speakerCard or null;
  dpi = machine.dpi or 120;
  hasPanel = edidLaptop != ""; # ohne EDID bleibt autorandr aus

  laptopScreen = {
    enable = true;
    primary = true;
    mode = "1920x1200";
    position = "0x0";
  };

  monitorScreen = {
    enable = true;
    mode = "1920x1080";
    position = "1920x0"; # rechts neben dem Laptop
  };

  # picom-Config mit Animation gegen das Aufblitzen beim Gruppenwechsel
  picomConf = pkgs.writeText "picom.conf" ''
    backend = "glx";
    vsync = true;
    use-damage = false;
    xrender-sync-fence = true;

    animations = (
      {
        triggers = [ "hide" ];
        opacity = { duration = 0.04; start = 1; end = 1; };
      }
    );
  '';

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

  # autorandr beim Auf- und Zuklappen auslösen (über den Dienst, kein Doppellauf)
  services.acpid = lib.mkIf hasPanel {
    enable = true;
    lidEventCommands = "systemctl start autorandr.service";
  };

  # Monitor-Profile automatisch wechseln
  services.autorandr = {
    enable = hasPanel;
    profiles = {
      # Dock dran, Laptop offen: beide Bildschirme
      dock = {
        fingerprint = {
          ${panel} = edidLaptop;
          DP-3-2 = edidMonitor;
        };
        config = {
          ${panel} = laptopScreen;
          DP-3-2 = monitorScreen;
        };
      };

      # Dock dran, Laptop zu: nur der große Monitor
      dock-zu = {
        fingerprint.DP-3-2 = edidMonitor;
        config = {
          ${panel}.enable = false;
          DP-3-2 =
            monitorScreen
            // {
              primary = true;
              position = "0x0";
            };
        };
      };

      # HDMI dran, Laptop offen: beide Bildschirme
      hdmi = {
        fingerprint = {
          ${panel} = edidLaptop;
          HDMI-1 = edidMonitorHdmi;
        };
        config = {
          ${panel} = laptopScreen;
          HDMI-1 = monitorScreen;
        };
      };

      # HDMI dran, Laptop zu: nur der große Monitor
      hdmi-zu = {
        fingerprint.HDMI-1 = edidMonitorHdmi;
        config = {
          ${panel}.enable = false;
          HDMI-1 =
            monitorScreen
            // {
              primary = true;
              position = "0x0";
            };
        };
      };

      # Kein Dock: nur Laptop-Display
      mobil = {
        fingerprint.${panel} = edidLaptop;
        config.${panel} = laptopScreen;
      };
    };
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

  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
      horizontalScrolling = false;
    };
  };

  services.xserver.dpi = dpi; # 96 = 100 %, 120 = 125 %, 144 = 150 %

  # Kein Tearing: picom mit VSync, Config siehe picomConf oben
  services.picom.enable = true;
  systemd.user.services.picom.serviceConfig.ExecStart =
    lib.mkForce "${pkgs.picom}/bin/picom --config ${picomConf}";

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

  home-manager.users.marc.services.dunst.enable = true;
}
