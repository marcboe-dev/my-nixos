{pkgs, ...}: {
  home.packages = [pkgs.kitty];
  home.sessionVariables.TERMINAL = "kitty";
}
