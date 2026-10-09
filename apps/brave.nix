{ pkgs, ... }:

{
  programs.brave = {
    enable = true;
    package = pkgs.brave;

    # Chrome-Web-Store-IDs: der letzte Teil der Store-URL
    # z.B. https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm
    extensions = [
      { id = "ioimlbgefgadofblnajllknopjboejda"; } # Transpose
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "jcokkipkhhgiakinbnnplhkdbjbgcgpe"; } # uBlock-origin
      { id = "khncfooichmfjbepaaaebmommgaepoid"; } # unHook
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # vimium
      { id = "cakobppopkpmmglabcdcklncbckjpkcl"; } # voila - KI
      { id = "hdojabcconedhifhdaeifnkdagccaflk"; } # Youtube-Transcript Extractor
    ];

    commandLineArgs = [
      "--enable-accelerated-video-decode"
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
}
