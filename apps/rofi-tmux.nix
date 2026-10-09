{ pkgs, ... }:
let
  mkScript = name: deps: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = deps;
    text = builtins.readFile (../scripts + "/${name}.sh");
  };
in
{
  home.packages = [
    (mkScript "rofi-repos"
      (with pkgs; [ rofi tmux alacritty findutils coreutils procps ]))
    (mkScript "rofi-sessions"
      (with pkgs; [ rofi tmux alacritty gnused coreutils procps ]))
    (mkScript "rofi-bookmarks"
      (with pkgs; [ rofi gnugrep gnused coreutils util-linux xdg-utils ]))
  ];
}
