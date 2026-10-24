{...}: {
  imports = [./hardware-configuration.nix];

  # Desktop dieses Laptops: "niri" (Wayland, Kitty) oder "qtile" (X11, Alacritty).
  # Ändern: hier umstellen ODER  install t490 niri|qtile  erneut ausführen.
  my.desktop = "niri";

  # Laptop-Teile einschalten, Werte dieser Maschine (von install.sh ausgelesen)
  my.laptop = {
    enable = true;
    panel = "eDP-1";
    edid = "00ffffffffffff0009e5c90700000000011c0104a51e117802fb90955d59942923505400000001010101010101010101010101010101393780de703814403020360035ad1000001a2d2c80de703814403020360035ad1000001a000000fe00424f452043510a202020202020000000fe004e5631343046484d2d4e34380a0078";
    speakerCard = null; # optional: Name aus  pactl list cards short
    dpi = 120; # nur qtile: 96 = 100 %, 120 = 125 %, 144 = 150 %
  };
}
