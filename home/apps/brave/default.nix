{
  pkgs,
  lib,
  ...
}: {
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
      {id = "dbepggeogbaibhgnhhndojpepiihcmeb";} # vimium
      {id = "cakobppopkpmmglabcdcklncbckjpkcl";} # voila - KI
      {id = "hdojabcconedhifhdaeifnkdagccaflk";} # Youtube-Transcript Extractor
      {id = "omkfmpieigblcllmkgbflkikinpkodlk";} # enhanced-h264ify (AV1 blockieren)
    ];

    commandLineArgs = [
      "--enable-accelerated-video-decode"
      "--force-dark-mode"
      "--disable-features=TouchpadOverscrollHistoryNavigation,UseChromeOSDirectVideoDecoder,OutdatedBuildDetector"
      # Mehrere eigene Extensions: nur EIN --load-extension-Flag, Pfade per Komma trennen
      "--load-extension=${./youtube-hl},${./tab-nav},${./readline-keys}"
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
