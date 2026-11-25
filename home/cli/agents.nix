# ─────────────────────────────────────────────────────────────────────
# opencode (AI-Coding-Agent im Terminal) mit Anthropic-API
#
# Ablegen unter: home/cli/agents.nix
# Einbinden in:  home/cli/default.nix  →  imports = [ ... ./agents.nix ];
#
# API-Key kommt NICHT ins Repo (der Nix-Store ist weltlesbar!).
# Einmalig pro Rechner anlegen:
#   mkdir -p ~/.config/secrets && chmod 700 ~/.config/secrets
#   printf '%s' 'sk-ant-...' > ~/.config/secrets/anthropic-api-key
#   chmod 600 ~/.config/secrets/anthropic-api-key
# Alternative ohne Datei: `opencode auth login` (speichert den Key in
# ~/.local/share/opencode/auth.json, ebenfalls außerhalb des Stores).
# ─────────────────────────────────────────────────────────────────────
{
  config,
  pkgs,
  ...
}: let
  keyFile = "${config.home.homeDirectory}/.config/secrets/anthropic-api-key";
in {
  programs.opencode = {
    enable = true;

    # Gemeinsamer Kontext für den Agent (wird zu ~/.config/opencode/AGENTS.md)
    rules = ''
      # Kontext
      - Das System ist NixOS (Flake, Home Manager). Dotfiles liegen in ~/nixos-dotfiles.
      - Änderungen an der Config immer deklarativ in Nix machen, nie imperativ per
        `nix-env` oder `nix profile`.
      - Neue Dateien erst mit `git add` stagen, sonst sieht der Flake sie nicht.
      - Nix-Code im Stil von alejandra formatieren.
      - Antworten auf Deutsch, Code und Kommentare im Repo auf Deutsch.
    '';

    settings = {
      "$schema" = "https://opencode.ai/config.json";

      # Mit `opencode models` prüfen, ob die ID bei dir so verfügbar ist
      model = "anthropic/claude-sonnet-5-5";
      small_model = "anthropic/claude-haiku-5-5";

      # Updates kommen über nixpkgs, nicht über opencode selbst
      autoupdate = false;
      # Sessions nicht auf opencode.ai teilbar machen
      share = "disabled";
    };
  };

  # API-Key erst beim Shell-Start aus der Datei lesen (nicht im Store, nicht im Repo)
  programs.bash.initExtra = ''
    if [ -r "${keyFile}" ]; then
      export ANTHROPIC_API_KEY="$(< "${keyFile}")"
    fi
  '';

  programs.bash.shellAliases.oc = "opencode";
}
