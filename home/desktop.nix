{pkgs, ...}: let
  mkScript = name: deps:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = deps;
      text = builtins.readFile (../scripts + "/${name}.sh");
    };
in {
  home.packages = with pkgs; [
    rofi
    noctalia
    alsa-utils
    swaybg
    (mkScript "dfr-screenshot" [grim slurp jq wl-clipboard satty coreutils])
    (mkScript "dfr-launch-or-focus" [jq])
    (mkScript "dfr-launch-or-focus-tui" [jq alacritty])
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
