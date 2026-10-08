{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "marc";
  home.homeDirectory = "/home/marc";

  # git-config declarative
  programs.git = {
    enable = true;
    settings = {
      user.name = "Marc";
      user.email = "marc.boehme186@gmail.com";
      init.defaultBranch = "main";
      };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo I use nixos, btw";
    };
  };

  home.stateVersion = "26.05"; # Please read the comment before changing.

  home.packages = [
  ];

  home.file = {
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true; # Let Home Manager install and manage itself.
}
