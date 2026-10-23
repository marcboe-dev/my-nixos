{
  pkgs,
  lib,
  ...
}: let
  desktop = "io.github.celluloid_player.Celluloid.desktop";
  videoTypes = [
    "video/mp4"
    "video/x-matroska"
    "video/webm"
    "video/quicktime"
    "video/x-msvideo"
    "video/mpeg"
    "video/ogg"
    "video/x-flv"
    "video/x-ms-wmv"
    "video/3gpp"
    "video/mp2t"
    "video/x-m4v"
  ];
in {
  home.packages = [pkgs.celluloid];

  # Celluloid als Standard für Videos (gilt für xdg-open, Thunar, Browser-Downloads …)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.genAttrs videoTypes (_: [desktop]);
  };
}
