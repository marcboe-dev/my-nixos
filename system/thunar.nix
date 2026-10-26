{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      # Plugin sucht .tap-Wrapper nur im eigenen libexec → xarchiver.tap dort verlinken
      (thunar-archive-plugin.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            ln -s ${xarchiver}/libexec/thunar-archive-plugin/xarchiver.tap \
              $out/libexec/thunar-archive-plugin/
          '';
      }))
      thunar-volman
    ];
  };

  programs.xfconf.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  environment.systemPackages = with pkgs; [
    xarchiver
    unar # entpackt fast alles, auch selbstentpackende .exe
    ffmpegthumbnailer
  ];

  # Sammelstelle für Thunar-Rechtsklick-Aktionen:
  # Jedes Home-Manager-Modul hängt seine <action>-Blöcke an my.thunar.actions an,
  # hier wird daraus ~/.config/Thunar/uca.xml gebaut.
  home-manager.sharedModules = [
    ({
      config,
      lib,
      ...
    }: {
      options.my.thunar.actions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "XML-Blöcke <action>…</action> für Thunar/uca.xml";
      };
      config.xdg.configFile."Thunar/uca.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <actions>
        ${lib.concatStringsSep "\n" config.my.thunar.actions}
        </actions>
      '';
    })
  ];

  home-manager.users.marc = {
    my.thunar.actions = [
      ''
        <action>
          <icon>utilities-terminal</icon>
          <name>Open Terminal Here</name>
          <submenu></submenu>
          <unique-id>1792620919862406-1</unique-id>
          <command>exo-open --working-directory %f --launch TerminalEmulator</command>
          <description>Terminal im aktuellen Ordner öffnen</description>
          <range></range>
          <patterns>*</patterns>
          <startup-notify/>
          <directories/>
        </action>
      ''
      ''
        <action>
          <icon>package-x-generic</icon>
          <name>Hier entpacken (unar)</name>
          <submenu></submenu>
          <unique-id>1792620919862406-3</unique-id>
          <command>sh -c '${pkgs.unar}/bin/unar -o "$(dirname "$1")" "$1" &amp;&amp; ${pkgs.libnotify}/bin/notify-send "Entpackt" "$(basename "$1")" || ${pkgs.libnotify}/bin/notify-send -u critical "Entpacken fehlgeschlagen" "$(basename "$1")"' _ %f</command>
          <description>Archiv oder selbstentpackende .exe mit unar entpacken</description>
          <range></range>
          <patterns>*.exe;*.zip;*.rar;*.7z;*.tar;*.tar.gz;*.tgz;*.tar.xz;*.txz;*.tar.bz2;*.tar.zst;*.gz;*.xz;*.bz2;*.zst;*.cab;*.iso;*.lzh;*.arj</patterns>
          <other-files/>
        </action>
      ''
    ];

    # Thunar-Werkzeugleiste (Split-View, Terminal, Google-Drive-Sync).
    # Fehlt eine Aktion (z. B. ohne Google-Drive-Modul), ignoriert Thunar den Eintrag.
    xfconf.settings.thunar = {
      "last-toolbar-items" = "menu:0,back:1,forward:1,open-parent:1,open-home:1,new-tab:0,new-window:0,toggle-split-view:1,undo:1,redo:1,zoom-out:0,zoom-in:0,zoom-reset:0,view-as-icons:0,view-as-detailed-list:0,view-as-compact-list:0,view-switcher:0,location-bar:1,reload:0,search:1,uca-action-1792620919862406-1:1,uca-action-1792620919862406-2:1";
    };

    xdg.configFile."xfce4/helpers.rc".text = ''
      TerminalEmulator=${config.my.terminal}
    '';

    xdg.mimeApps = {
      enable = true;
      defaultApplications."inode/directory" = ["thunar.desktop"];
    };

    gtk = {
      enable = true;
      theme = {
        name = "Tokyonight-Dark-Moon";
        package = pkgs.tokyonight-gtk-theme.override {
          colorVariants = ["dark"];
          tweakVariants = ["moon"];
        };
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      font = {
        name = "FreeSans";
        package = pkgs.freefont_ttf;
        size = 11;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
