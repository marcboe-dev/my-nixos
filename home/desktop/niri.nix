# ─────────────────────────────────────────────────────────────────────
# Home-Teil für niri (Inhalt aus home/desktop.nix auf niri-test)
# ─────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  link = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${name}";
    recursive = true;
  };

  # Shell-Skript aus scripts/ als eigenes Programm verpacken.
  # deps = Programme, die das Skript zur Laufzeit im PATH braucht.
  # ../../ weil diese Datei in home/desktop/ liegt.
  mkScript = name: deps:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = deps;
      text = builtins.readFile (../../scripts + "/${name}.sh");
    };

  # Noctalia mit gestaffeltem Text in Kalender-Erinnerungen:
  #   unter 60 min      → "Starts in X min"   (Original-Text)
  #   60 min bis < 24 h → "Starts in X hours" (gerundet)
  #   ab 24 h           → "Starts in X days"  (gerundet)
  # --replace-fail lässt den Build absichtlich scheitern, falls sich die Zeile
  # in einer neuen Noctalia-Version ändert.
  noctaliaPatched = pkgs.noctalia.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace src/calendar/calendar_reminder_monitor.cpp \
          --replace-fail \
            ': i18n::tr("notifications.internal.calendar-reminder-in", "minutes", minutes, "time", timeText);' \
            ': minutes >= 1440
                ? std::format("Starts in {} {} · {}", (minutes + 720) / 1440, (minutes + 720) / 1440 == 1 ? "day" : "days", timeText)
                : minutes >= 60
                ? std::format("Starts in {} {} · {}", (minutes + 30) / 60, (minutes + 30) / 60 == 1 ? "hour" : "hours", timeText)
                : i18n::tr("notifications.internal.calendar-reminder-in", "minutes", minutes, "time", timeText);'
      '';
  });
in
  lib.mkIf (osConfig.my.desktop == "niri") {
    home.packages = with pkgs; [
      noctaliaPatched # Bar / Shell (Erinnerungen in min/h/Tagen), wird in config.kdl gestartet
      swaybg # Wallpaper unter Wayland
      wl-clipboard # wl-copy für tmux (Ctrl+Shift+Enter)
      (mkScript "dfr-screenshot" [grim slurp jq wl-clipboard satty coreutils procps])
      (mkScript "dfr-launch-or-focus" [jq])
      (mkScript "dfr-launch-or-focus-tui" [jq kitty])
    ];

    # Einheitliches Cursor-Theme (inkl. Crosshair für slurp), skaliert sauber
    home.pointerCursor = {
      enable = true;
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
      gtk.enable = true;
    };

    # Damit ~/Pictures sicher existiert (sonst kann satty nicht speichern)
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    # ~/.config/<name> → ~/nixos-dotfiles/config/<name>
    xdg.configFile = {
      niri = link "niri";
      noctalia = link "noctalia";
      satty = link "satty";
    };
  }
