{...}: {
  imports = [
    # Folder
    ./desktop # Desktop-Auswahl über my.desktop (siehe system/desktop/default.nix)
    ./laptop

    # Files
    ./brave-policy.nix
    ./thunar.nix
    ./terminal.nix
  ];
}
