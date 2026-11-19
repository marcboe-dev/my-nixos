{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../profiles/workstation.nix
  ];

  # Die VM läuft immer mit X11 + qtile (unter VMware flüssiger als Wayland).
  # install.sh ignoriert bei der VM jede andere Desktop-Angabe.
  my.desktop = "qtile";
  my.terminal = "alacritty";

  # Wie kanata auf dem Host (VMware greift die Tasten VOR kanata ab):
  # linke Alt der Aula sendet ralt → als echtes Alt behandeln,
  # rechte Strg wird AltGr (für @ { [ ] } \ ~).
  services.keyd.keyboards.default.settings.main = {
    rightalt = "layer(alt)";
    rightcontrol = "layer(altgr)";
  };

  networking.networkmanager.insertNameservers = ["1.1.1.1" "9.9.9.9"];

  virtualisation.vmware.guest.enable = true; # copying from host to vm

  # VM-spezifische X11-Einstellung: feste Auflösung im VMware-Fenster.
  services.xserver.extraConfig = ''
    Section "Monitor"
      Identifier "Virtual-1"
      Option "PreferredMode" "1920x1080"
    EndSection
  '';

  # Zugriff aufs Tailnet (SSH zum Server). Kein Exit Node in der VM.
  services.tailscale.enable = true;
}
