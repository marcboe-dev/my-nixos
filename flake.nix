{
  description = "NixOS from Scratch";

  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
      home-manager = {
          url = "github:nix-community/home-manager/release-26.05";
          inputs.nixpkgs.follows = "nixpkgs";# versions nixpkgs & home-manger same
      };

  };

    outputs = { self, nixpkgs, home-manager, ... }:
  let
    # Funktion: bekommt einen Host-Ordner, gibt ein komplettes System zurück
    mkHost = hostDir: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix   # gemeinsam
        hostDir               # rechnerspezifisch
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.marc = import ./home.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
  in {
    nixosConfigurations = {
      nixos-vm = mkHost ./hosts/vm;
      nixos-laptop = mkHost ./hosts/laptop;
    };
  };

}
