{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../profiles/server.nix
  ];

  # ── Nur diese Maschine (von install.sh ausgelesen) ──────────────
  # Wake-on-LAN: zusätzlich im BIOS einschalten. Geht nur per Kabel und am Netzteil.
  networking.interfaces."enp0s31f6".wakeOnLan.enable = true;

  # Akku schonen im Dauerbetrieb am Netzteil
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
}
