# ─────────────────────────────────────────────────────────────────────
# Laptop-Teile, die NUR unter X11/qtile gebraucht werden.
#
# Aktiv nur bei  my.laptop.enable = true;  UND  my.desktop = "qtile";
# Unter niri macht niri das selbst: Monitore und Touchpad in config.kdl,
# VSync im Compositor, Benachrichtigungen über noctalia.
#
# Die VM nutzt diese Datei nicht (my.laptop.enable ist dort false) und
# hat ihre eigenen X11-Einstellungen in hosts/vm/default.nix.
# ─────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.laptop;

  # ── Externe Monitore an deinem Dock (für autorandr) ──────────────
  edidMonitor = "00ffffffffffff0030aecd62000000002b1f0104a5351f783a0565a756529c270f5054afef00714f8180818a9500a9c0a9cfb300d1cf023a801871382d40582c45000f282100001e000000fd00324c1e5512000a202020202020000000fc005432346d2d32300a2020202020000000ff00563930385a5050300a2020202001a3020318f14b901f04130302121101051423090f0783010000023a801871382d40582c45000f282100001e011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f282100001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000df"; # autorandr --fingerprint → DP-3-2
  edidMonitorHdmi = "00ffffffffffff0030aecd62000000002b1f010380351f782a0565a756529c270f5054afef00714f8180818a9500a9c0a9cfb300d1cf023a801871382d40582c45000f282100001e000000fc005432346d2d32300a2020202020000000fd00324c1e5512000a202020202020000000ff00563930385a5050300a2020202001d902031ef14b9005040302011f1213141123090f078301000065030c001000023a801871382d40582c45000f282100001e011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f28210000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000055"; # autorandr --fingerprint → HDMI-1

  # ── Pro Maschine aus my.laptop ───────────────────────────────────
  panel = cfg.panel;
  edidLaptop = cfg.edid;
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
in
  lib.mkIf (cfg.enable && config.my.desktop == "qtile") {
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

    # Touchpad unter X11 (unter niri: input-Block in config.kdl)
    services.libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        horizontalScrolling = false;
      };
    };

    services.xserver.dpi = cfg.dpi;

    # Kein Tearing: picom mit VSync, Config siehe picomConf oben
    services.picom.enable = true;
    systemd.user.services.picom.serviceConfig.ExecStart =
      lib.mkForce "${pkgs.picom}/bin/picom --config ${picomConf}";
  }
