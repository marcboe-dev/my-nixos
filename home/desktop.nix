{pkgs, ...}: {
  home.packages = with pkgs; [
    rofi
    noctalia
    alsa-utils
    swaybg
    fuzzel
  ];

  services.flameshot = {
    enable = true;
    settings.General = {
      showStartupLaunchMessage = false;
      disabledTrayIcon = true;
      useX11LegacyScreenshot = true;
    };
  };
}
