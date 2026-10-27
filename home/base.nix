# ─────────────────────────────────────────────────────────────────────
# Home-Manager-Basis für JEDEN Rechner (Workstation und Server)
#
# Wird in flake.nix für alle Hosts geladen. Das Workstation-Profil hängt
# zusätzlich home/workstation.nix an (siehe profiles/workstation.nix).
# ─────────────────────────────────────────────────────────────────────
{config, ...}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Ordner aus config/ → ~/.config/<n>
  configs = {
    nvim = "nvim";
    tmux = "tmux";
    cheatsheets = "cheatsheets";
  };
in {
  imports = [
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

  # Automatisch aufräumen: deine User-Profile (Home Manager), wöchentlich, älter als 7 Tage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
