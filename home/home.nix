{config, ...}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Ordner aus config/ → ~/.config/<name>
  configs = {
    qtile = "qtile";
    nvim = "nvim";
    rofi = "rofi";
    alacritty = "alacritty";
    tmux = "tmux";
    rmpc = "rmpc";
  };
in {
  imports = [
    ./desktop.nix
    ./apps
    ./cli
  ];

  home.username = "marc";
  home.homeDirectory = "/home/marc";
  home.stateVersion = "26.05";

  xdg.configFile =
    builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;

  programs.home-manager.enable = true; # Let Home Manager install and manage itself.
}
