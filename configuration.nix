{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ./system
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-vm"; # Define your hostname.

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Vienna";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_AT.UTF-8";
    LC_IDENTIFICATION = "de_AT.UTF-8";
    LC_MEASUREMENT = "de_AT.UTF-8";
    LC_MONETARY = "de_AT.UTF-8";
    LC_NAME = "de_AT.UTF-8";
    LC_NUMERIC = "de_AT.UTF-8";
    LC_PAPER = "de_AT.UTF-8";
    LC_TELEPHONE = "de_AT.UTF-8";
    LC_TIME = "de_AT.UTF-8";
  };

  # services.desktopManager.gnome.enable = true;

  services.displayManager.ly.enable = true;

  services.xserver = {
  enable = true;
  autoRepeatDelay = 200;
  autoRepeatInterval = 35;
  windowManager.qtile.enable = true;
  displayManager.sessionCommands = ''
  xwallpaper --zoom ~/nixos-dotfiles/walls/wall1.png
  '';
  xkb = {
  layout = "at";
  variant = "";
  };
  extraConfig = ''
    Section "Monitor"
      Identifier "Virtual-1"
      Option "PreferredMode" "1920x1080"
    EndSection
  '';
  };

  # Configure keymap in X11
  # services.xserver.xkb = {
  #   layout = "at";
  #   variant = "";
  # };

  services.printing.enable = true;

  services.pulseaudio.enable = false; # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users."marc" = {
    isNormalUser = true;
    description = "marc";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  
  # Workaround: nixpkgs baut qtile 0.37.1 gegen wlroots 0.19, braucht aber 0.20
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyfinal: pyprev: {
          qtile = pyprev.qtile.override { wlroots = final.wlroots_0_20; };
        })
      ];
    })
  ];

  environment.systemPackages = with pkgs; [
     neovim 
     wget
     git
     # wl-clipboard
     alacritty
    ];

  system.stateVersion = "26.05"; 
  
  fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  virtualisation.vmware.guest.enable = true; # copying from host to vm

  # Caps Lock: click once = Esc, hold = Ctrl
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        capslock = "overload(control, esc)";
      };
    };
  };
}
