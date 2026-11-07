{
  pkgs,
  lib,
  vimium-src, # kommt aus flake.nix (extraSpecialArgs), Version steht in flake.lock
  ...
}: let
  # Eigene Vimium-Optionen; werden als Vimiums Standardwerte eingebaut.
  # Nicht in der Vimium-Optionsseite ändern, sondern hier.
  vimiumSettings = {
    keyMappings = ''
      unmap p
      unmap P
      map gs focusScrollable
    '';
    newTabDestination = "customUrl";
    newTabCustomUrl = "https://duckduckgo.com/";
  };

  vimiumOverrides = pkgs.writeText "vimium-overrides.js" ''
    Object.assign(Settings.defaultOptions, ${builtins.toJSON vimiumSettings});
  '';

  # Vimium-Quellcode + eigene Defaults → entpackte Extension (läuft auch auf file://)
  vimium = pkgs.runCommand "vimium-declarative" {} ''
    cp -r ${vimium-src} $out
    chmod -R u+w $out
    grep -q "defaultOptions," $out/lib/settings.js \
      || { echo "Vimium: defaultOptions nicht gefunden – Patch prüfen"; exit 1; }
    cat ${vimiumOverrides} >> $out/lib/settings.js

    # Eigener Befehl "focusScrollable": Hints auf scrollbare Bereiche (siehe ./vimium-scroll-picker/)
    grep -q "^export { allCommands };" $out/background_scripts/all_commands.js \
      || { echo "Vimium: allCommands-Export nicht gefunden – Patch prüfen"; exit 1; }
    cat ${./vimium-scroll-picker/command.js} >> $out/background_scripts/all_commands.js
    cat ${./vimium-scroll-picker/picker.js} >> $out/content_scripts/mode_normal.js
  '';
in {
  programs.brave = {
    enable = true;
    package = pkgs.brave;

    # Chrome-Web-Store-IDs: der letzte Teil der Store-URL
    # z.B. https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm
    extensions = [
      {id = "ioimlbgefgadofblnajllknopjboejda";} # Transpose
      {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
      {id = "jcokkipkhhgiakinbnnplhkdbjbgcgpe";} # uBlock-origin
      {id = "khncfooichmfjbepaaaebmommgaepoid";} # unHook
      # {id = "dbepggeogbaibhgnhhndojpepiihcmeb";} # vimium
      {id = "cakobppopkpmmglabcdcklncbckjpkcl";} # voila - KI
      {id = "hdojabcconedhifhdaeifnkdagccaflk";} # Youtube-Transcript Extractor
      {id = "omkfmpieigblcllmkgbflkikinpkodlk";} # enhanced-h264ify (AV1 blockieren)
    ];

    commandLineArgs = [
      "--enable-accelerated-video-decode"
      "--force-dark-mode"
      "--disable-features=TouchpadOverscrollHistoryNavigation,UseChromeOSDirectVideoDecoder,OutdatedBuildDetector"
      # Mehrere eigene Extensions: nur EIN --load-extension-Flag, Pfade per Komma trennen
      "--load-extension=${./tab-nav},${./readline-keys},${vimium}"
    ];
  };

  # Brave als Standardbrowser
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
    };
  };

  # Brave als Auswahl in yazi bei "O" (open interactively)
  programs.yazi.settings = {
    opener.brave = [
      {
        run = "brave %s";
        orphan = true; # Brave läuft weiter, auch wenn yazi geschlossen wird
        desc = "Brave";
        for = "unix";
      }
    ];

    # mkBefore: diese Regeln kommen VOR denen aus yazi.nix (erste passende Regel gewinnt).
    # Der erste Opener bleibt jeweils wie bisher, d.h. Enter/l verhält sich unverändert,
    # Brave taucht nur zusätzlich in der O-Liste auf.
    open.prepend_rules = lib.mkBefore [
      {
        mime = "application/pdf";
        use = ["pdf" "brave" "reveal"];
      }
      {
        mime = "text/*";
        use = ["edit" "brave" "reveal"];
      } # html, md, txt …
      {
        mime = "image/*";
        use = ["open" "brave" "reveal"];
      } # inkl. svg
      {
        mime = "video/*";
        use = ["play" "brave" "reveal"];
      }
      {
        mime = "application/{json,ndjson,javascript}";
        use = ["edit" "brave" "reveal"];
      }
    ];
  };
}
