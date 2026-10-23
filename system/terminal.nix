# Standard-Terminal pro Host, analog zu my.desktop.
# Der Host setzt z.B.  my.terminal = "alacritty";  Default ist "kitty".
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my.terminal = lib.mkOption {
    type = lib.types.enum ["kitty" "alacritty"];
    # qtile (X11) → Alacritty, niri (Wayland) → Kitty.
    # Ein Host kann das mit  my.terminal = "...";  trotzdem überschreiben.
    default =
      if config.my.desktop == "qtile"
      then "alacritty"
      else "kitty";
    defaultText = lib.literalExpression ''if my.desktop == "qtile" then "alacritty" else "kitty"'';
    description = "Standard-Terminal dieses Hosts.";
  };

  config = {
    # Nur das gewählte Terminal wird installiert
    environment.systemPackages = [pkgs.${config.my.terminal}];

    # Systemweit, damit auch qtile und rofi die Variable sehen
    environment.sessionVariables.TERMINAL = config.my.terminal;
  };
}
