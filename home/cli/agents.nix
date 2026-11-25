# ─────────────────────────────────────────────────────────────────────
# opencode (AI-Coding-Agent im Terminal) mit Anthropic-API
#
# Ablegen unter: home/cli/agents.nix
# Einbinden in:  home/cli/default.nix  →  imports = [ ... ./agents.nix ];
#
# Grundidee: opencode darf NICHTS ändern oder ausführen, ohne dass du
# es im Terminal bestätigst. Nur Lesen ist frei.
#
# API-Key kommt NICHT ins Repo (der Nix-Store ist weltlesbar!).
# Einmalig pro Rechner anlegen:
#   mkdir -p ~/.config/secrets && chmod 700 ~/.config/secrets
#   printf '%s' 'sk-ant-...' > ~/.config/secrets/anthropic-api-key
#   chmod 600 ~/.config/secrets/anthropic-api-key
# Alternative ohne Datei: `opencode auth login`.
# ─────────────────────────────────────────────────────────────────────
{config, ...}: let
  keyFile = "${config.home.homeDirectory}/.config/secrets/anthropic-api-key";
in {
  programs.opencode = {
    enable = true;

    # Globale Regeln: bewusst klein und projektunabhängig.
    # Projektspezifischer Kontext (z.B. Lebenslauf) gehört in eine AGENTS.md
    # im jeweiligen Projektordner, nicht hierher.
    rules = ''
      # Arbeitsweise
      - Ich entscheide, was geändert wird. Du schlägst vor, ich bestätige.
      - Erst erklären, was du ändern willst und warum, dann ändern.
      - Immer nur kleine, einzeln nachvollziehbare Änderungen.
      - Nichts erfinden. Bei fehlenden Informationen nachfragen.
      - Antworten auf Deutsch.
    '';

    settings = {
      "$schema" = "https://opencode.ai/config.json";

      # Mit `opencode models` prüfen, ob die ID bei dir so verfügbar ist
      model = "anthropic/claude-sonnet-5-5";
      small_model = "anthropic/claude-haiku-5-5";

      # Lesen/Suchen im Projekt ist immer erlaubt. Für alles, was etwas
      # verändert oder nach außen geht, wird vorher gefragt:
      permission = {
        edit = "ask"; # Dateien ändern oder anlegen
        bash = "ask"; # Shell-Befehle
        webfetch = "ask"; # Webseiten abrufen
      };
      # Später lockern, z.B.: bash = { "*" = "ask"; "git status" = "allow"; "git diff*" = "allow"; };

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
