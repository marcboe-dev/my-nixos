# ─────────────────────────────────────────────────────────────────────
# Home-Teil für niri (Inhalt aus home/desktop.nix auf niri-test)
# ─────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  link = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${name}";
    recursive = true;
  };

  # Shell-Skript aus scripts/ als eigenes Programm verpacken.
  # deps = Programme, die das Skript zur Laufzeit im PATH braucht.
  # ../../ weil diese Datei in home/desktop/ liegt.
  mkScript = name: deps:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = deps;
      text = builtins.readFile (../../scripts + "/${name}.sh");
    };
in
  lib.mkIf (osConfig.my.desktop == "niri") {
    home.packages = with pkgs; [
      noctalia # Bar / Shell, wird in config.kdl gestartet
      swaybg # Wallpaper unter Wayland
      (mkScript "dfr-screenshot" [grim slurp jq wl-clipboard satty coreutils procps])
      (mkScript "dfr-launch-or-focus" [jq])
      (mkScript "dfr-launch-or-focus-tui" [jq kitty])
    ];

    # Damit ~/Pictures sicher existiert (sonst kann satty nicht speichern)
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    # ~/.config/<name> → ~/nixos-dotfiles/config/<name>
    xdg.configFile = {
      niri = link "niri";
      noctalia = link "noctalia";
      satty = link "satty";
    };
  }
