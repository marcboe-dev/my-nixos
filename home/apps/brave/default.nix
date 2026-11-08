{
  pkgs,
  lib,
  vimium-src, # kommt aus flake.nix (extraSpecialArgs), Version steht in flake.lock
  ...
}: let
  # Suchmaschinen – EINE Liste für beides:
  #  * Omnibar:          !<key> suchbegriff
  #  * searchSelection:  s, dann <key> (Kleinbuchstabe = neuer Tab, Großbuchstabe = aktueller Tab)
  # key muss ein einzelner Kleinbuchstabe sein (searchSelection liest nur eine Taste).
  # Reihenfolge = Reihenfolge in der searchSelection-Anzeige.
  searchEngines = [
    {
      key = "g";
      name = "Google";
      url = "https://www.google.com/search?q=";
    }
    {
      key = "d";
      name = "DuckDuckGo";
      url = "https://duckduckgo.com/?q=";
    }
    {
      key = "h";
      name = "GitHub";
      url = "https://github.com/search?q=";
    }
    {
      key = "c";
      name = "GitHub-Code";
      url = "https://github.com/search?type=code&q=";
    }
    {
      key = "y";
      name = "YouTube";
      url = "https://www.youtube.com/results?search_query=";
    }
    {
      key = "e";
      name = "Wikipedia";
      url = "https://de.wikipedia.org/w/index.php?search=";
    }
    {
      key = "s";
      name = "StackOverflow";
      url = "https://stackoverflow.com/search?q=";
    }
    {
      key = "a";
      name = "ArchWiki";
      url = "https://wiki.archlinux.org/index.php?search=";
    }
    {
      key = "k";
      name = "Google-Maps";
      url = "https://www.google.com/maps?q=";
    }
    {
      key = "n";
      name = "Nix-Pakete";
      url = "https://search.nixos.org/packages?query=";
    }
    {
      key = "o";
      name = "NixOS-Optionen";
      url = "https://search.nixos.org/options?query=";
    }
    {
      key = "m";
      name = "Home-Manager";
      url = "https://home-manager-options.extranix.com/?query=";
    }
    {
      key = "w";
      name = "NixOS-Wiki";
      url = "https://wiki.nixos.org/w/index.php?search=";
    }
  ];

  # Prüft beim Build: Einzelbuchstabe, keine doppelten Kürzel
  checkedEngines = let
    keys = map (e: e.key) searchEngines;
  in
    assert lib.all (k: builtins.match "[a-z]" k != null) keys
    || throw "searchEngines: key muss ein einzelner Kleinbuchstabe sein";
    assert lib.length keys
    == lib.length (lib.unique keys)
    || throw "searchEngines: doppeltes Kürzel"; searchEngines;

  # search.js mit der Liste von oben (Platzhalter @ENGINES@)
  searchSelectionJs = let
    src = builtins.readFile ./vimium-search-selection/search.js;
  in
    assert lib.hasInfix "@ENGINES@" src
    || throw "search.js: Platzhalter @ENGINES@ fehlt";
      pkgs.writeText "search.js"
      (builtins.replaceStrings ["@ENGINES@"] [(builtins.toJSON checkedEngines)] src);
  # Eigene Vimium-Optionen; werden als Vimiums Standardwerte eingebaut.
  # Nicht in der Vimium-Optionsseite ändern, sondern hier.
  vimiumSettings = {
    keyMappings = ''
      unmap p
      unmap P
      unmap J
      unmap K
      map gs focusScrollable
      map v visualHints
      map s searchSelection
    '';
    newTabDestination = "customUrl";
    newTabCustomUrl = "https://duckduckgo.com/";

    # Standardsuche der Omnibar (o/O). Vimium-Default wäre Google.
    # Mit DuckDuckGo funktionieren zusätzlich alle DDG-Bangs, die unten nicht stehen.
    searchUrl = "https://duckduckgo.com/?q=";

    # Omnibar-Kürzel: "!y lofi" → YouTube. Erzeugt aus searchEngines (siehe oben im let).
    searchEngines = lib.concatMapStrings (e: "!${e.key}: ${e.url}%s ${e.name}\n") checkedEngines;
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

    # Eigener Befehl "visualHints": Surfingkeys-artiger Visual-Mode (siehe ./vimium-visual-hints/)
    cat ${./vimium-visual-hints/command.js} >> $out/background_scripts/all_commands.js
    cat ${./vimium-visual-hints/picker.js} >> $out/content_scripts/mode_normal.js

    # Eigener Befehl "searchSelection": Markierung/Kopiertes suchen (siehe ./vimium-search-selection/)
    cat ${./vimium-search-selection/command.js} >> $out/background_scripts/all_commands.js
    cat ${searchSelectionJs} >> $out/content_scripts/mode_normal.js
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
      "--load-extension=${./tab-nav},${./readline-keys},${./youtube-speed},${vimium}"
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
