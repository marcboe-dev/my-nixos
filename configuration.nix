{pkgs, ...}: {
  imports = [
    ./system
  ];

  # ── Nix ──────────────────────────────────────────────
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  # ── Boot ─────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Optional: NTFS-Sticks (exFAT/FAT/ext4 gehen schon über den Kernel)
  boot.supportedFilesystems = ["ntfs"];

  # ── Netzwerk ─────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ── Zeit & Sprache ───────────────────────────────────
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

  # ── Benutzer ─────────────────────────────────────────
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

  # ── Desktop & Anzeige ────────────────────────────────
  # services.desktopManager.gnome.enable = true;

  services.displayManager.ly.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb = {
  #   layout = "at";
  #   variant = "";
  # };

  programs.dconf.enable = true; # for gtk-windows to remember their size

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # ── Tastatur ─────────────────────────────────────────
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

  # ── Audio ────────────────────────────────────────────
  services.pulseaudio.enable = false; # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── Hardware & Laufwerke ─────────────────────────────
  services.printing.enable = true;

  services.udisks2.enable = true; # Externe Drives (zB USB, externe Festplatte)

  # ── Programme ────────────────────────────────────────
  programs.firefox.enable = true;

  programs.neovim = {
    # setze neovim als Standardeditor
    enable = true;
    defaultEditor = true; # setzt EDITOR=nvim für die ganze Session
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    man-pages # Linux-/glibc-Manpages: printf(3), malloc(3), open(2) …
    man-pages-posix # POSIX-Varianten (Sektion 0p/1p/3p)
  ];

  # ── Dokumentation ────────────────────────────────────
  documentation.dev.enable = true; #installiert auch Entwickler-Manpages (devman/devdoc) der Pakete

  # ── State Version (nicht ändern) ─────────────────────
  system.stateVersion = "26.05";
}
