{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.rmpc];

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
