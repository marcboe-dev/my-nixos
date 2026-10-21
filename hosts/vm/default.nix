{...}: {
  imports = [./hardware-configuration.nix];

  networking.networkmanager.insertNameservers = ["1.1.1.1" "9.9.9.9"];

  virtualisation.vmware.guest.enable = true; # copying from host to vm

  services.xserver.extraConfig = ''
    Section "Monitor"
      Identifier "Virtual-1"
      Option "PreferredMode" "1920x1080"
    EndSection
  '';
}
