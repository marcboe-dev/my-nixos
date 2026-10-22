# ─────────────────────────────────────────────────────────────────────
# X11 + qtile (für alle Hosts mit  my.desktop = "qtile";)
#
# Gemeinsam für VM UND Laptops. Was nur die VM braucht, steht in
# hosts/vm/default.nix; was nur Laptops unter X11 brauchen, in
# hosts/laptop-qtile.nix.
# ─────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  ...
}:
lib.mkIf (config.my.desktop == "qtile") {
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.qtile.enable = true; # legt die qtile-Session für ly an

    # Wallpaper beim Start der X-Session setzen.
    # xwallpaper selbst wird in home/desktop/qtile.nix installiert.
    displayManager.sessionCommands = ''
      xwallpaper --zoom ~/nixos-dotfiles/walls/wall1.png
    '';

    # Tastaturlayout für X11. (niri setzt sein Layout selbst in config.kdl.)
    xkb = {
      layout = "at";
      variant = "";
    };
  };

  # Workaround: nixpkgs baut qtile 0.37.1 gegen wlroots 0.19, braucht aber 0.20.
  # Gehört zu qtile, deshalb nur aktiv, wenn qtile auch benutzt wird.
  # Wenn nixpkgs das selbst behoben hat, kann dieser Block weg.
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (pyfinal: pyprev: {
            qtile = pyprev.qtile.override {wlroots = final.wlroots_0_20;};
          })
        ];
    })
  ];
}
