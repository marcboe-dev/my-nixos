
**Vorschlag für die Struktur:**

```
├── flake.nix
nixos-config/
├── hosts/
│   ├── vm/                  # VMware Workstation Pro
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   └── baremetal/
│       ├── configuration.nix
│       └── hardware-configuration.nix
├── system/                  # NixOS-Ebene (root, /etc)
│   ├── default.nix
│   └── brave-policy.nix
└── home/                    # Home-Manager-Ebene (dein User)
    ├── home.nix
    ├── apps/                # GUI-Programme
    │   ├── default.nix
    │   ├── brave.nix
    │   ├── obsidian.nix
    │   └── google-drive.nix
    └── cli/                 # Terminal-Tools
        ├── default.nix
        ├── neovim.nix
        └── tmux.nix
```

**`home/apps/default.nix`**

```nix
{
  imports = [
    ./brave.nix
    ./obsidian.nix
    ./google-drive.nix
  ];
}
```

**`home/home.nix`**

```nix
{
  imports = [
    ./apps
    ./cli
  ];

  home.username = "marc";
  home.homeDirectory = "/home/marc";
  home.stateVersion = "26.05";
}
```

`./apps` lädt automatisch `./apps/default.nix`.

**Warum diese Aufteilung:**

- **`system/` und `home/` getrennt:** Die Brave-Policy muss nach `/etc` und gehört deshalb zur Systemebene. `brave.nix` mit den Erweiterungen ist dagegen Home-Manager. Wenn du das trennst, verwechselst du die beiden Ebenen nicht.
- **`hosts/vm` und `hosts/baremetal`:** Hier liegen nur die Unterschiede, z.B. Hardware und VMware-Tools. `system/` und `home/` teilen sich beide Hosts. Das deckt deine Anforderung „VM und bare metal“ ab.
- **`apps/` getrennt von `cli/`:** Später kannst du z.B. für einen Server-Host nur `cli/` einbinden.

Bevor du Obsidian und Google Drive angehst, solltest du zwei Dinge wissen:

- **Obsidian ist unfree.** Du brauchst `nixpkgs.config.allowUnfree = true;`. Am saubersten setzt du das zentral in der `flake.nix`.
- **Google Drive hat keinen offiziellen Linux-Client.** Die üblichen Wege unter NixOS sind `rclone` mit Mount als systemd-User-Service (deklarativ und kostenlos) oder `insync` (unfree und kostenpflichtig). Ich würde `rclone` nehmen. Der Login per OAuth bleibt aber einmalig ein manueller Schritt, der sich nicht vollständig reproduzieren lässt.
