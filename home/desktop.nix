{pkgs, ...}: let
  dfr-screenshot = pkgs.writeShellApplication {
    name = "dfr-screenshot";
    runtimeInputs = with pkgs; [grim slurp jq wl-clipboard satty coreutils];
    text = builtins.readFile ../scripts/dfr-screenshot.sh;
  };
in {
  home.packages = with pkgs; [
    rofi
    noctalia
    alsa-utils
    swaybg
    fuzzel
    dfr-screenshot
  ];

  # Damit ~/Pictures sicher existiert (sonst kann satty nicht speichern)
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  services.flameshot = {
    enable = true;
    settings.General = {
      showStartupLaunchMessage = false;
      disabledTrayIcon = true;
      useX11LegacyScreenshot = true;
    };
  };
}
