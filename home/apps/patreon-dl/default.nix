# ─────────────────────────────────────────────────────────────────────
# patreon-dl: Patreon-Kurs offline speichern (Anleitung: ./README.md)
#
# Alles liegt in diesem Ordner. Zum Entfernen:
#   1. Ordner home/apps/patreon-dl/ löschen
#   2. Zeile ./patreon-dl in home/apps/default.nix löschen
#   3. nrs
# ─────────────────────────────────────────────────────────────────────
{pkgs, ...}: let
  patreonDl = pkgs.writeShellApplication {
    name = "patreon-dl";
    runtimeInputs = [
      # secretstorage: zum Entschlüsseln der Brave-Cookies über den Keyring
      (pkgs.python3.withPackages (ps: [ps.requests ps.yt-dlp ps.secretstorage]))
      pkgs.ffmpeg # zum Zusammenfügen von HLS-Videos
    ];
    text = ''exec python3 ${./patreon-dl.py} "$@"'';
  };
in {
  home.packages = [patreonDl];
}
