# ─────────────────────────────────────────────────────────────────────
# niri (Wayland)
#
# Aktiv, wenn der Host my.desktop = "niri" setzt ODER gar nichts setzt
# (Default, siehe system/desktop/default.nix).
# ─────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  ...
}: let
  nirinitCfg = config.services.nirinit;

  # Layout speichern, Fenster sortiert nach Spalte (links → rechts).
  # nirinit selbst speichert in zufälliger Reihenfolge, dadurch kamen die
  # Fenster nach dem Neustart vertauscht zurück. Schreibt dieselbe
  # session.json wie nirinit 0.3.0.
  #   nirinit-save           → speichern + Benachrichtigung
  #   nirinit-save --quiet   → speichern ohne Benachrichtigung (Timer)
  nirinitSave = pkgs.writeShellApplication {
    name = "nirinit-save";
    runtimeInputs = [config.programs.niri.package pkgs.jq pkgs.coreutils pkgs.libnotify];
    text = ''
      out="''${XDG_DATA_HOME:-$HOME/.local/share}/nirinit/session.json"
      mkdir -p "$(dirname "$out")"

      ws="$(niri msg --json workspaces)"
      niri msg --json windows | jq \
        --argjson ws "$ws" \
        --argjson launch '${builtins.toJSON nirinitCfg.settings.launch}' '
        map(. as $w
          | (first($ws[] | select(.id == $w.workspace_id)) // null) as $s
          | {w: $w, s: $s})
        | sort_by([.s.output, .s.idx, (.w.layout.pos_in_scrolling_layout // [99999, 99999])])
        | map({
            id: .w.id,
            app_id: .w.app_id,
            launch_command: (if .w.app_id == null then null else ($launch[.w.app_id] // .w.app_id) end),
            workspace_idx: .s.idx,
            workspace_name: .s.name,
            workspace_output: .s.output,
            is_focused: .w.is_focused,
            window_size: .w.layout.window_size
          })' > "$out.tmp"
      mv "$out.tmp" "$out"

      if [ "''${1:-}" != "--quiet" ]; then
        notify-send "nirinit" "Layout gespeichert" || true
      fi
    '';
  };
in
  lib.mkIf (config.my.desktop == "niri") {
    programs.niri.enable = true; # legt die niri-Session für ly an

    # Session-Manager: stellt Fenster/Workspaces beim Login wieder her.
    services.nirinit = {
      enable = true;
      settings = {
        # Projekt-Terminals (rofi) mit der letzten tmux-Session neu öffnen
        launch."dfr.tmux" = "kitty --class dfr.tmux -e tmux-attach-last";
        skip.apps = [];
      };
    };

    # nirinit soll nur noch WIEDERHERSTELLEN. Sein eigenes Speichern
    # (unsortiert) praktisch abschalten: Intervall = 10 Jahre.
    # Das Modul bietet dafür keine Option, daher den Startbefehl überschreiben.
    systemd.user.services.nirinit.serviceConfig.ExecStart = lib.mkForce (
      "${lib.getExe nirinitCfg.package} --save-interval 315360000 --config "
      + "${(pkgs.formats.toml {}).generate "nirinit-config.toml" nirinitCfg.settings}"
    );

    # Stattdessen speichert nirinit-save jede Minute (sortiert).
    systemd.user.services.nirinit-save = {
      description = "niri-Layout für nirinit speichern";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${nirinitSave}/bin/nirinit-save --quiet";
      };
    };
    systemd.user.timers.nirinit-save = {
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      timerConfig = {
        OnActiveSec = "2min"; # erst nach dem Restore beim Login
        OnUnitActiveSec = "1min";
      };
    };

    # Electron/Chromium-Apps (Brave, Obsidian, Signal) nativ unter Wayland
    # starten statt über XWayland. Unter X11 hätte das keinen Sinn.
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # Diese Liste wird von Nix automatisch mit environment.systemPackages
    # aus configuration.nix zusammengeführt – nichts wird überschrieben.
    environment.systemPackages = with pkgs; [
      wl-clipboard # Zwischenablage unter Wayland (wl-copy / wl-paste)
      xwayland-satellite # damit X11-only-Apps unter niri laufen
      nirinitSave # manuell: Mod+Alt+S
    ];
  }
