{...}: {
  imports = [
    ./hardware-configuration.nix
    (import ../laptop-common.nix (import ./machine.nix))
  ];

  # Desktop dieses Laptops: "niri" (Wayland) oder "qtile" (X11).
  # Ändern: hier umstellen ODER  install t14 niri|qtile  erneut ausführen.
  my.desktop = "niri";
}
