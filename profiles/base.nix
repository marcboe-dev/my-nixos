# ─────────────────────────────────────────────────────────────────────
# Basis für JEDEN Rechner (Workstation und Server)
#
# Wird im flake.nix für alle Hosts geladen. Was ein Host zusätzlich ist,
# entscheidet er selbst über ein Profil in hosts/<n>/default.nix:
#
#     imports = [ ../../profiles/workstation.nix ];   # Desktop-Rechner
#     imports = [ ../../profiles/server.nix ];        # Server (headless)
#
# Hier gehört nur hinein, was auch auf einem Server ohne Bildschirm
# sinnvoll ist. Alles Grafische steht in profiles/workstation.nix.
# ─────────────────────────────────────────────────────────────────────
{pkgs, ...}: {
  # ── Nix ──────────────────────────────────────────────
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  # Automatisch aufräumen: wöchentlich, alles älter als 7 Tage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.optimise.automatic = true; # Doppelte Dateien im Store zusammenführen (spart Platz)

  boot.loader.systemd-boot.configurationLimit = 10; # Maximal 10 Einträge im Bootmenü (verhindert volle /boot-Partition)

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

  # ── Tastatur ─────────────────────────────────────────
  # Layout der Textkonsole (TTY). Die grafischen Sitzungen setzen ihr
  # Layout selbst: niri in config/niri/config.kdl, qtile in system/desktop/qtile.nix.
  console.keyMap = "de-latin1-nodeadkeys";

  # Caps Lock: click once = Esc, hold = Ctrl
  # Auch am Server praktisch, wenn man direkt davorsitzt (Notfall-Konsole).
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = ["*"];
      settings = {
        global.chord_timeout = 70;
        main = {
          capslock = "overload(control, esc)";
          "j+k" = "esc";
        };
      };
    };
  };

  # ── Programme ────────────────────────────────────────
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
