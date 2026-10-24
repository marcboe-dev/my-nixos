{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.rmpc];

  # Upstream-.desktop hat kein Icon → gleichnamig überschreiben
  xdg.desktopEntries.rmpc = {
    name = "rmpc";
    genericName = "Music Player";
    comment = "Terminal-basierter MPD-Client";
    exec = "rmpc";
    terminal = true;
    icon = "org.gnome.Music"; # aus Papirus-Dark
    categories = ["AudioVideo" "Audio" "Player"];
  };

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
      auto_update "yes"
    '';
  };

  # mpd startet nicht, wenn der Musikordner fehlt (frische Installation)
  home.file."Music/.keep".text = "";
}
