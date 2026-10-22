# ─────────────────────────────────────────────────────────────────────
# Desktop-Auswahl pro Host
#
# Hier wird die eigene Option `my.desktop` definiert. Jeder Host kann sie
# in hosts/<name>/default.nix setzen, z.B.:
#
#     my.desktop = "qtile";
#
# Setzt ein Host nichts, gilt der Default "niri".
#
# WICHTIG zum Verständnis:
#   Beide Desktop-Module werden IMMER importiert. Jedes Modul prüft selbst
#   per lib.mkIf, ob es gemeint ist, und ist sonst leer.
#   "Importiert" heißt hier also NICHT "aktiv".
#
# Home-Manager liest dieselbe Option über `osConfig` mit
# (siehe home/desktop/). Es gibt also genau EINE Stelle, die entscheidet.
# ─────────────────────────────────────────────────────────────────────
{lib, ...}: {
  # imports dürfen nie innerhalb von lib.mkIf stehen: Nix muss die Liste
  # aller Module kennen, bevor es überhaupt Optionen auswerten kann.
  imports = [
    ./qtile.nix
    ./niri.nix
  ];

  options.my.desktop = lib.mkOption {
    # enum = nur diese Werte sind erlaubt. Ein Tippfehler wie "nirri"
    # lässt den Build sofort mit einer klaren Fehlermeldung abbrechen.
    type = lib.types.enum ["niri" "qtile"];
    default = "niri";
    description = "Grafische Session dieses Hosts (niri = Wayland, qtile = X11).";
  };
}
