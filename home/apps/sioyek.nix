{pkgs, ...}: {
  home.packages = [pkgs.sioyek];

  # Sioyek als Standard für PDF
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = ["sioyek.desktop"];
    };
  };
}
