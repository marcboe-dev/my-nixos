{
  config,
  osConfig,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  term = osConfig.my.terminal;

  # Ordner aus config/ → ~/.config/<name>
  configs = {
    nvim = "nvim";
    rofi = "rofi";
    tmux = "tmux";
    rmpc = "rmpc";
    cheatsheets = "cheatsheets";
    ${term} = term; # VM: alacritty, T14: kitty
  };
in {
  imports = [
    ./desktop
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

  # Benachrichtigungen bei external Drives
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never"; # kein Tray nötig
  };
}
