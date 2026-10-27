# ─────────────────────────────────────────────────────────────────────
# Home-Manager-Teil NUR für Workstations
#
# Wird von profiles/workstation.nix angehängt, zusätzlich zu home/base.nix.
# Hier darf osConfig.my.desktop / osConfig.my.terminal benutzt werden,
# weil es diese Optionen auf Workstations immer gibt.
# ─────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  term = osConfig.my.terminal;

  # Ordner aus config/ → ~/.config/<n>
  configs = {
    rofi = "rofi";
    rmpc = "rmpc";
    ${term} = term; # VM: alacritty, T14: kitty
  };
in {
  imports = [
    ./desktop
    ./apps
    ./cli/rmpc.nix # Musik-Client + mpd: braucht Audio, nur hier
  ];

  xdg.configFile =
    builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;

  # Bildvorschau in yazi unter Alacritty (Kitty kann das selbst)
  home.packages = lib.optional (term == "alacritty") pkgs.ueberzugpp;

  # Benachrichtigungen bei external Drives
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never"; # kein Tray nötig
  };
}
