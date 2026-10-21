{pkgs, ...}: {
  home.packages = with pkgs; [
    rofi
    xwallpaper
    xclip
    maim #screenshots
    alsa-utils #advanced linux sound architecture
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
