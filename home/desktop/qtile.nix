# ─────────────────────────────────────────────────────────────────────
# Home-Teil für X11 + qtile (Inhalt aus home/desktop.nix auf main)
# ─────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
in
  lib.mkIf (osConfig.my.desktop == "qtile") {
    home.packages = with pkgs; [
      xwallpaper # Wallpaper, wird in system/desktop/qtile.nix aufgerufen
      xclip # Zwischenablage unter X11
      maim # Screenshots
    ];

    # Screenshot-Tool, in config/qtile/config.py an eine Taste gebunden.
    # (Unter niri übernimmt das das dfr-screenshot-Skript mit satty.)
    services.flameshot = {
      enable = true;
      settings.General = {
        showStartupLaunchMessage = false;
        disabledTrayIcon = true;
        useX11LegacyScreenshot = true;
      };
    };

    # ~/.config/qtile → ~/nixos-dotfiles/config/qtile
    # Out-of-store-Symlink: Änderungen wirken ohne Rebuild.
    xdg.configFile.qtile = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/qtile";
      recursive = true;
    };
  }
