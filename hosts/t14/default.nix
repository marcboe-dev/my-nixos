{...}: {
  imports = [
    ./hardware-configuration.nix
    (import ../laptop-common.nix (import ./machine.nix))
  ];
}
