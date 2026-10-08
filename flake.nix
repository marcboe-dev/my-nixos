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
      nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
	  modules = [ 
              ./configuration.nix 
	      home-manager.nixosModules.home-manager
	      {
	          home-manager = {
                      useGlobalPkgs = true;
                      useUserPackages = true;
                      users.marc = import ./home.nix;
		      backupFileExtension = "backup"; # when downloading a .config-file, and this .configfile already exists, instead of crashing it moves file to backup-directory
		  };
	      };
	  ];
      };

}
