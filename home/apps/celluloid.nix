{
  pkgs,
  lib,
  config,
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

  # mpv-Keybinds im vim-Stil
  xdg.configFile."celluloid/input.conf".text = ''
    h seek -5
    l seek 5
    H seek -30
    L seek 30
    j add volume -5
    k add volume 5
    0 seek 0 absolute
    ? script-binding stats/display-page-4-toggle

  '';

  # Lesbare Einblendungen: dunkler Kasten hinter dem Text
  xdg.configFile."celluloid/mpv.conf".text = ''
    osd-border-style=background-box
    osd-back-color="#FF000000"
    osd-font-size=40
    osd-align-x=left
    osd-align-y=top
  '';

  xdg.configFile."celluloid/script-opts/stats.conf".text = ''
    key_scroll_down=Ctrl+j
    key_scroll_up=Ctrl+k
    scroll_lines=3
  '';

  dconf.settings."io/github/celluloid-player/celluloid" = {
    mpv-input-config-enable = true;
    mpv-input-config-file = "file://${config.xdg.configHome}/celluloid/input.conf";
    mpv-config-enable = true;
    mpv-config-file = "file://${config.xdg.configHome}/celluloid/mpv.conf";
  };

  # Celluloid als Standard für Videos (gilt für xdg-open, Thunar, Browser-Downloads …)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.genAttrs videoTypes (_: [desktop]);
  };
}
