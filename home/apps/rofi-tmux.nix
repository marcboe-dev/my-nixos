{pkgs, ...}: let
  mkScript = name: deps:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = deps;
      text = builtins.readFile (../../scripts + "/${name}.sh");
    };

  repos =
    mkScript "rofi-repos"
    (with pkgs; [rofi tmux kitty findutils coreutils procps]);
  sessions =
    mkScript "rofi-sessions"
    (with pkgs; [rofi tmux kitty gnused coreutils procps]);
  bookmarks =
    mkScript "rofi-bookmarks"
    (with pkgs; [rofi gnugrep gnused coreutils util-linux xdg-utils]);
in {
  home.packages = [
    repos
    sessions
    bookmarks
    (mkScript "rofi-launch" [pkgs.rofi repos sessions bookmarks])
  ];
}
