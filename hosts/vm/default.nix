{...}: {
  imports = [./hardware-configuration.nix];

  # Die VM läuft immer mit X11 + qtile (unter VMware flüssiger als Wayland).
  # install.sh ignoriert bei der VM jede andere Desktop-Angabe.
  my.desktop = "qtile";

  networking.networkmanager.insertNameservers = ["1.1.1.1" "9.9.9.9"];

  virtualisation.vmware.guest.enable = true; # copying from host to vm

  # VM-spezifische X11-Einstellung: feste Auflösung im VMware-Fenster.
  services.xserver.extraConfig = ''
    Section "Monitor"
      Identifier "Virtual-1"
      Option "PreferredMode" "1920x1080"
    EndSection
  '';
}
