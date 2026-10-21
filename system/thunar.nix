{pkgs, ...}: {
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin # "Hier entpacken" im Kontextmenü
      thunar-volman # Wechseldatenträger
    ];
  };

  programs.xfconf.enable = true; # Thunar-Einstellungen speichern
  services.gvfs.enable = true; # Papierkorb, Mounts, Netzwerk
  services.tumbler.enable = true; # Thumbnails

  environment.systemPackages = with pkgs; [
    xarchiver # Archivprogramm für das Archive-Plugin
    ffmpegthumbnailer # Video-Thumbnails
  ];

  # Thunar als Standard für Ordner (Home-Manager-Teil, direkt hier mit drin)
  home-manager.users.marc.xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = ["thunar.desktop"];
  };
}
