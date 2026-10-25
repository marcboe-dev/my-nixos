{
  config,
  pkgs,
  lib,
  ...
}: let
  home = config.home.homeDirectory;
  mountDir = "${home}/GoogleDrive";

  # ============================================================
  # HIER die zu synchronisierenden Ordner eintragen
  # ~/<Name>  <->  gdrive:<Name>
  # ============================================================
  syncFolders = [
    "Documents/recipes"
  ];

  bisync = pkgs.writeShellApplication {
    name = "gdrive-bisync";
    runtimeInputs = with pkgs; [rclone coreutils util-linux libnotify getent];
    text = ''
      # Von Hand:   gdrive-bisync          -> meldet immer das Ergebnis
      # Vom Timer:  gdrive-bisync --timer  -> meldet nur Fehler
      timer=0
      if [ "''${1:-}" = "--timer" ]; then timer=1; fi

      notify() { notify-send -a "Google Drive" "$@" || true; }

      state="${home}/.local/state/gdrive-bisync"
      mkdir -p "$state"

      # Nie zwei Läufe gleichzeitig: Timer überspringt, Handstart wartet
      exec 9>"$state/lock"
      if [ "$timer" = 1 ]; then
        flock -n 9 || exit 0
      else
        flock 9
      fi

      # Offline: Timer bleibt still, Handstart sagt Bescheid
      if ! getent hosts www.googleapis.com >/dev/null; then
        [ "$timer" = 1 ] || notify "Kein Internet" "Nicht synchronisiert"
        exit 0
      fi

      ok=()
      failed=()
      folders=(${lib.escapeShellArgs syncFolders})
      for folder in "''${folders[@]}"; do
        local_dir="${home}/$folder"
        marker="$state/$(echo "$folder" | tr / _).ok"
        mkdir -p "$local_dir"

        extra=()
        if [ ! -e "$marker" ]; then
          echo "$folder: erster Lauf auf diesem Rechner -> --resync"
          extra=(--resync)
        fi

        if rclone mkdir "gdrive:$folder" && rclone bisync "gdrive:$folder" "$local_dir" \
            "''${extra[@]}" \
            --create-empty-src-dirs \
            --resilient --recover \
            --conflict-resolve newer \
            --max-lock 2m \
            --drive-skip-gdocs \
            --verbose; then
          touch "$marker"
          ok+=("$folder")
        else
          failed+=("$folder")
        fi
      done

      if [ "''${#failed[@]}" -gt 0 ]; then
        if [ "$timer" = 1 ]; then
          details="journalctl --user -u gdrive-bisync -e"
        else
          details="siehe Ausgabe im Terminal"
        fi
        notify -u critical "Sync fehlgeschlagen" "''${failed[*]}"$'\n'"Details: $details"
        exit 1
      fi

      [ "$timer" = 1 ] || notify "Synchronisiert" "''${ok[*]}"
    '';
  };
in {
  home.packages = [pkgs.rclone bisync];

  # Thunar: benutzerdefinierte Aktionen (Terminal + Google Drive Sync)
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
      <icon>utilities-terminal</icon>
      <name>Open Terminal Here</name>
      <submenu></submenu>
      <unique-id>1792620919862406-1</unique-id>
      <command>exo-open --working-directory %f --launch TerminalEmulator</command>
      <description>Example for a custom action</description>
      <range></range>
      <patterns>*</patterns>
      <startup-notify/>
      <directories/>
    </action>
    <action>
      <icon>view-refresh</icon>
      <name>Google Drive synchronisieren</name>
      <submenu></submenu>
      <unique-id>1792620919862406-2</unique-id>
      <command>${bisync}/bin/gdrive-bisync</command>
      <description>Sync all bisync folders with Google Drive now</description>
      <range></range>
      <patterns>*</patterns>
      <directories/>
      <audio-files/>
      <image-files/>
      <other-files/>
      <text-files/>
      <video-files/>
    </action>
    </actions>
  '';

  # Thunar: Werkzeugleiste (Split-View, Terminal, Google-Drive-Sync)
  xfconf.settings.thunar = {
    "last-toolbar-items" = "menu:0,back:1,forward:1,open-parent:1,open-home:1,new-tab:0,new-window:0,toggle-split-view:1,undo:1,redo:1,zoom-out:0,zoom-in:0,zoom-reset:0,view-as-icons:0,view-as-detailed-list:0,view-as-compact-list:0,view-switcher:0,location-bar:1,reload:0,search:1,uca-action-1792620919862406-1:1,uca-action-1792620919862406-2:1";
  };

  # --- Mount: ganzes Drive unter ~/GoogleDrive ---
  systemd.user.services.gdrive-mount = {
    Unit = {
      Description = "Google Drive via rclone";
      # Startet erst, wenn rclone einmal eingerichtet wurde (sonst Fehlerschleife)
      ConditionPathExists = "%h/.config/rclone/rclone.conf";
    };
    Service = {
      Type = "notify";
      Environment = ["PATH=/run/wrappers/bin"]; # damit rclone fusermount3 findet
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountDir}";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive: ${mountDir} \
          --vfs-cache-mode full \
          --vfs-cache-max-size 10G \
          --dir-cache-time 1h
      '';
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = ["default.target"];
  };

  # --- Bisync: echte lokale Kopien der Ordner aus syncFolders ---
  systemd.user.services.gdrive-bisync = {
    Unit = {
      Description = "Google Drive bisync";
      ConditionPathExists = "%h/.config/rclone/rclone.conf";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${bisync}/bin/gdrive-bisync --timer";
    };
  };

  systemd.user.timers.gdrive-bisync = {
    Unit.Description = "Google Drive bisync alle 5 Minuten";
    Timer = {
      OnStartupSec = "1min";
      OnUnitActiveSec = "5min";
    };
    Install.WantedBy = ["timers.target"];
  };
}
