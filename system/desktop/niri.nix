# ─────────────────────────────────────────────────────────────────────
# niri (Wayland)
#
# Aktiv, wenn der Host my.desktop = "niri" setzt ODER gar nichts setzt
# (Default, siehe system/desktop/default.nix).
# ─────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.my.desktop == "niri") {
  programs.niri.enable = true; # legt die niri-Session für ly an

  # Session-Manager: speichert alle 5 Min. Fenster/Workspaces
  # und stellt sie beim Login wieder her.
  services.nirinit = {
    enable = true;
    settings.skip.apps = [];
  };

  # Electron/Chromium-Apps (Brave, Obsidian, Signal) nativ unter Wayland
  # starten statt über XWayland. Unter X11 hätte das keinen Sinn.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Diese Liste wird von Nix automatisch mit environment.systemPackages
  # aus configuration.nix zusammengeführt – nichts wird überschrieben.
  environment.systemPackages = with pkgs; [
    wl-clipboard # Zwischenablage unter Wayland (wl-copy / wl-paste)
    xwayland-satellite # damit X11-only-Apps unter niri laufen
  ];
}
