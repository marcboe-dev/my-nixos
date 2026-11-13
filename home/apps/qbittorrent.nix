{
  pkgs,
  lib,
  ...
}: let
  desktop = "org.qbittorrent.qBittorrent.desktop";
in {
  home.packages = [pkgs.qbittorrent];

  # Magnet-Links und .torrent-Dateien direkt mit qBittorrent öffnen (auch aus Brave)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.genAttrs [
      "application/x-bittorrent"
      "x-scheme-handler/magnet"
    ] (_: [desktop]);
  };
}
