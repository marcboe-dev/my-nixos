{
  pkgs,
  config,
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
    ffmpegthumbnailer
  ];

  home-manager.users.marc = {
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
