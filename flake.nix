{
  description = "NixOS from Scratch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # versions nixpkgs & home-manger same
    };
    nirinit = {
      url = "github:amaanq/nirinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    satty-src = {
      url = "github:Satty-org/Satty";
      flake = false; # nur der Quellcode, wird in flake.lock gepinnt
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nirinit,
    satty-src,
    ...
  }: let
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    # Jeder Ordner in hosts/ mit einer default.nix ist ein Host
    hostNames = builtins.attrNames (
      lib.filterAttrs
      (name: type: type == "directory" && builtins.pathExists (./hosts + "/${name}/default.nix"))
      (builtins.readDir ./hosts)
    );

    # Funktion: bekommt einen Host-Namen, gibt ein komplettes System zurück
    mkHost = name:
      lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./profiles/base.nix # gemeinsam für alle; die Rolle wählt der Host selbst
          # Satty aus main: frei belegbare Keybinds ("y" = kopieren).
          # Entfernen, sobald nixpkgs eine Satty-Version > 0.22.0 hat.
          {
            nixpkgs.overlays = [
              (final: prev: {
                satty = prev.satty.overrideAttrs (old: {
                  version = "0.22.0-unstable-${satty-src.lastModifiedDate}";
                  src = satty-src;
                  cargoDeps = final.rustPlatform.importCargoLock {
                    lockFile = "${satty-src}/Cargo.lock";
                  };
                  buildInputs = old.buildInputs ++ [final.fontconfig];
                  doCheck = false; # Tests brauchen xkbcommon/Display
                });
              })
            ];
          }
          nirinit.nixosModules.nirinit
          (./hosts + "/${name}") # rechnerspezifisch
          {networking.hostName = "nixos-${name}";}
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.marc = import ./home/base.nix; # Workstation-Teil hängt profiles/workstation.nix an
              backupFileExtension = "backup";
            };
          }
        ];
      };
  in {
    nixosConfigurations = builtins.listToAttrs (map (name: {
        name = "nixos-${name}";
        value = mkHost name;
      })
      hostNames);

    apps.x86_64-linux.default = {
      type = "app";
      meta.description = "Installiert diese NixOS-Config auf einem Host";
      program = "${pkgs.writeShellApplication {
        name = "install";
        runtimeInputs = [pkgs.git pkgs.coreutils pkgs.gnused pkgs.diffutils pkgs.systemd];
        text = builtins.readFile ./install.sh;
      }}/bin/install";
    };
  };
}
