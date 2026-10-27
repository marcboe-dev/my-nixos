# ─────────────────────────────────────────────────────────────────────
# Profil: Workstation (Laptop oder VM mit Desktop)
#
# Ein Host bekommt dieses Profil über hosts/<n>/default.nix:
#
#     imports = [ ../../profiles/workstation.nix ];
#
# Alles Grafische hängt hier dran – System UND Home-Manager. Ein neues
# App-Modul in home/apps/ landet dadurch automatisch NUR auf Workstations,
# nie auf dem Server. Es braucht dafür keine Bedingung (lib.mkIf).
#
# Die Optionen my.desktop, my.terminal und my.laptop gibt es nur auf
# Workstations: sie werden über ../system importiert.
# ─────────────────────────────────────────────────────────────────────
{pkgs, ...}: {
  imports = [
    ../system # desktop/ (my.desktop), laptop/ (my.laptop), terminal.nix (my.terminal), Brave, Thunar
  ];

  # Home-Manager: zusätzlich zu home/base.nix (kommt aus flake.nix)
  home-manager.users.marc.imports = [../home/workstation.nix];

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
}
