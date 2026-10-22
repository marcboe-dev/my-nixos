# ─────────────────────────────────────────────────────────────────────
# Desktop-Teil von Home-Manager
#
# Gemeinsames für beide Sessions steht direkt hier. Die session-
# spezifischen Teile liegen in qtile.nix und niri.nix und schalten sich
# über `osConfig.my.desktop` selbst ein oder aus.
#
# `osConfig` = die NixOS-Systemkonfiguration. Das Argument gibt es, weil
# Home-Manager bei dir als NixOS-Modul läuft (siehe flake.nix). So liest
# Home-Manager dieselbe Option wie das System – keine zweite Einstellung.
# ─────────────────────────────────────────────────────────────────────
{pkgs, ...}: {
  imports = [
    ./qtile.nix
    ./niri.nix
  ];

  home.packages = with pkgs; [
    rofi # Launcher, unter X11 und Wayland
    alsa-utils # advanced linux sound architecture
  ];
}
