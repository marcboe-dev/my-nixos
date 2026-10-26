{
  pkgs,
  lib,
  ...
}: let
  desktop = "imv-dir.desktop";
  imageTypes = [
    "image/png"
    "image/jpeg"
    "image/webp"
    "image/gif"
    "image/bmp"
    "image/tiff"
    "image/avif"
    "image/svg+xml"
  ];

  # Hilfe als Benachrichtigung (15 Sekunden sichtbar)
  imvHelp = pkgs.writeShellScript "imv-help" ''
    ${pkgs.libnotify}/bin/notify-send -t 15000 "imv Shortcuts" \
    "h / l       vorheriges / nächstes Bild
    Pfeile      Bild verschieben
    gg / G      erstes / letztes Bild
    i / o       rein- / rauszoomen
    a           Originalgröße
    r           Zoom zurücksetzen
    c           zentrieren
    s           Skalierung wechseln
    Ctrl+r      90° drehen
    f           Vollbild
    d           Overlay mit Infos
    t / T       Diashow
    x           aus Liste entfernen
    q           beenden"
  '';
in {
  programs.imv = {
    enable = true;
    settings = {
      options.loop_input = true;
      binds = {
        h = "prev";
        l = "next";
        "<Left>" = "pan 50 0";
        "<Right>" = "pan -50 0";
        "<Up>" = "pan 0 50";
        "<Down>" = "pan 0 -50";
        "<Ctrl+r>" = "rotate by 90"; # im Uhrzeigersinn
        "<Ctrl+Shift+R>" = "rotate by -90"; # optional: gegen den Uhrzeigersinn
        "<Shift+question>" = "exec ${imvHelp}";
      };
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.genAttrs imageTypes (_: [desktop]);
  };
}
