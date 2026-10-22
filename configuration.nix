{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./system
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
      layout = "at-hjkl";
      variant = "";
      extraLayouts.at-hjkl = {
        description = "German (Austria) with AltGr+j = ĵ";
        languages = ["deu"];
        symbolsFile = pkgs.writeText "at-hjkl" ''
          xkb_symbols "at-hjkl" {
            include "at(basic)"
            name[Group1] = "German (Austria) hjkl";
            key <AC07> { [ j, J, U0135, U0134 ] };  // AltGr+j -> ĵ
          };
        '';
      };
    };
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

  users.groups.nordvpn = {};

  users.users."marc" = {
    isNormalUser = true;
    description = "marc";
    extraGroups = [
      "networkmanager"
      "wheel"
      "nordvpn"
    ];
  };

  programs.firefox.enable = true;

  programs.dconf.enable = true; # for gtk-windows to remember their size

  nixpkgs.config.allowUnfree = true;

  # Workaround: nixpkgs baut qtile 0.37.1 gegen wlroots 0.19, braucht aber 0.20
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (pyfinal: pyprev: {
            qtile = pyprev.qtile.override {wlroots = final.wlroots_0_20;};
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

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Caps Lock: click once = Esc, hold = Ctrl
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = ["*"];
      settings.main = {
        capslock = "overload(control, esc)";
      };
    };
  };

  # Externe Drives (zB USB, externe Festplatte)
  services.udisks2.enable = true;
  # Optional: NTFS-Sticks (exFAT/FAT/ext4 gehen schon über den Kernel)
  boot.supportedFilesystems = ["ntfs"];
}
