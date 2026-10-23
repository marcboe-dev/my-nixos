{...}: {
  imports = [./hardware-configuration.nix];

  # Desktop dieses Laptops: "niri" (Wayland, Kitty) oder "qtile" (X11, Alacritty).
  # Ändern: hier umstellen ODER  install t14 niri|qtile  erneut ausführen.
  my.desktop = "niri";

  # Laptop-Teile einschalten, Werte dieser Maschine
  my.laptop = {
    enable = true;
    panel = "eDP-1";
    edid = "00ffffffffffff0006af91d200000000161e0104a51e1378034bdca855499c220e505600000001010101010101010101010101010101fa3c80b870b0244010103e002dbc10000018000000fd00303c4b4b10010a202020202020000000fe0041554f0a202020202020202020000000fe004231343055414e30322e31200a0089";
    speakerCard = "alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic";
    dpi = 120; # nur qtile: 96 = 100 %, 120 = 125 %, 144 = 150 %
  };
}
