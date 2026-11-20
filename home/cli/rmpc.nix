{
  config,
  pkgs,
  ...
}: let
  # Zusätzlicher Unix-Socket: nur darüber erlaubt mpd file://-URIs,
  # also Dateien AUSSERHALB von ~/Music (z. B. ~/Documents/guitar/...)
  mpdSocket = "${config.services.mpd.dataDir}/socket";

  # Von yazi als Opener genutzt: Queue leeren, gewählte Datei(en) rein,
  # abspielen, dann rmpc öffnen
  rmpc-open = pkgs.writeShellApplication {
    name = "rmpc-open";
    runtimeInputs = [pkgs.mpc pkgs.coreutils pkgs.rmpc];
    text = ''
      export MPD_HOST="${mpdSocket}"
      mpc -q clear
      for f in "$@"; do
        mpc -q add "file://$(realpath "$f")"
      done
      mpc -q play
      exec rmpc
    '';
  };
in {
  home.packages = [pkgs.rmpc pkgs.mpc rmpc-open];

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
      bind_to_address "${mpdSocket}"
    '';
  };

  # mpd startet nicht, wenn der Musikordner fehlt (frische Installation)
  home.file."Music/.keep".text = "";
}
