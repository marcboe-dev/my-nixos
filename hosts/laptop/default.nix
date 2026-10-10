{ pkgs, ... }:

let
  # ── Hier deine Werte eintragen ─────────────────────────────
  dockId      = "cf030000-0080-7718-a350-5310d8304021";   # cat /sys/bus/thunderbolt/devices/1-1/unique_id
  edidLaptop  = "00ffffffffffff0006af91d200000000161e0104a51e1378034bdca855499c220e505600000001010101010101010101010101010101fa3c80b870b0244010103e002dbc10000018000000fd00303c4b4b10010a202020202020000000fe0041554f0a202020202020202020000000fe004231343055414e30322e31200a0089";      # autorandr --fingerprint  → Zeile eDP-1
  edidMonitor = "00ffffffffffff0030aecd62000000002b1f0104a5351f783a0565a756529c270f5054afef00714f8180818a9500a9c0a9cfb300d1cf023a801871382d40582c45000f282100001e000000fd00324c1e5512000a202020202020000000fc005432346d2d32300a2020202020000000ff00563930385a5050300a2020202001a3020318f14b901f04130302121101051423090f0783010000023a801871382d40582c45000f282100001e011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f282100001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000df";     # autorandr --fingerprint  → Zeile DP-3-2

   edidMonitorHdmi = "00ffffffffffff0030aecd62000000002b1f010380351f782a0565a756529c270f5054afef00714f8180818a9500a9c0a9cfb300d1cf023a801871382d40582c45000f282100001e000000fc005432346d2d32300a2020202020000000fd00324c1e5512000a202020202020000000ff00563930385a5050300a2020202001d902031ef14b9005040302011f1213141123090f078301000065030c001000023a801871382d40582c45000f282100001e011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f28210000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000055";   # autorandr --fingerprint → Zeile HDMI-1
  # ───────────────────────────────────────────────────────────

  laptopScreen = {
    enable = true;
    primary = true;
    mode = "1920x1200";
    position = "0x0";
  };

  monitorScreen = {
    enable = true;
    mode = "1920x1080";
    position = "1920x0";   # rechts neben dem Laptop
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos-laptop";

  # ThinkPad Thunderbolt 3 Dock automatisch freigeben
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{unique_id}=="${dockId}", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';

  # Zuklappen: mit Monitor nichts tun, ohne Monitor Standby
  services.logind.settings.Login = {
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitch = "suspend";
  };

  # autorandr beim Auf- und Zuklappen auslösen (über den Dienst, kein Doppellauf)
  services.acpid = {
    enable = true;
    lidEventCommands = "systemctl start autorandr.service";
  };

  # Monitor-Profile automatisch wechseln
  services.autorandr = {
    enable = true;
    profiles = {
      # Dock dran, Laptop offen: beide Bildschirme
      dock = {
        fingerprint = { eDP-1 = edidLaptop; DP-3-2 = edidMonitor; };
        config      = { eDP-1 = laptopScreen; DP-3-2 = monitorScreen; };
      };

      # Dock dran, Laptop zu: nur der große Monitor
      dock-zu = {
        fingerprint.DP-3-2 = edidMonitor;
        config = {
          eDP-1.enable = false;
          DP-3-2 = monitorScreen // {
            primary = true;
            position = "0x0";
          };
        };
      };

      # HDMI dran, Laptop offen: beide Bildschirme
      hdmi = {
        fingerprint = { eDP-1 = edidLaptop; HDMI-1 = edidMonitorHdmi; };
        config      = { eDP-1 = laptopScreen; HDMI-1 = monitorScreen; };
      };

      # HDMI dran, Laptop zu: nur der große Monitor
      hdmi-zu = {
        fingerprint.HDMI-1 = edidMonitorHdmi;
        config = {
          eDP-1.enable = false;
          HDMI-1 = monitorScreen // {
            primary = true;
            position = "0x0";
          };
        };
      };

      # Kein Dock: nur Laptop-Display
      mobil = {
        fingerprint.eDP-1 = edidLaptop;
        config.eDP-1 = laptopScreen;
      };
    };
  };

  environment.systemPackages = [ pkgs.pavucontrol pkgs.brightnessctl];

    # Soundprofil mit Laptop-Lautsprechern festlegen
  services.pipewire.wireplumber.extraConfig."51-laptop-speaker" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "device.name" = "alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic"; }
        ];
        actions.update-props = {
          "device.profile" = "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)";
        };
      }
    ];
  };
}
