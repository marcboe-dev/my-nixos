{
  lib,
  config,
  pkgs,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Standard .config/directory
  configs = {
    qtile = "qtile";
    nvim = "nvim";
    rofi = "rofi";
    alacritty = "alacritty";
    tmux = "tmux";
    rmpc = "rmpc";
  };
in {
  imports = [
    ./apps
  ];

  home.username = "marc";
  home.homeDirectory = "/home/marc";
  programs.git.enable = true;
  home.stateVersion = "26.05";
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos-btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
      vi = "nvim";
    };
    initExtra = ''
      export PS1="\[\e[38;5;75m\]\u@\h \[\e[38;5;113m\]\w \[\e[38;5;189m\]\$ \[\e[0m\]"

       export EDITOR=nvim
       export VISUAL=nvim

       export MANPAGER="nvim +Man!"
       export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    '';
  };

  xdg.configFile =
    builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;

  # Sioyek as standard for pdf
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = ["sioyek.desktop"];
    };
  };

  home.packages = with pkgs; [
    neovim
    ripgrep
    nil
    alejandra #ersetzt nixpkgs-fmt
    clang-tools #clang-d + clang-format
    nodejs
    gcc
    gnumake
    rofi
    xwallpaper
    xclip
    maim #screenshots
    alsa-utils #advanced linux sound architecture
    tmux
    btop
    ueberzugpp
    bat

    obsidian
    signal-desktop
    sioyek
    rmpc
  ];

  programs.git = {
    settings = {
      user.name = "marc";
      user.email = "marc.boehme186@example.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
    };
  };

  programs.lazygit.enable = true;
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  services.flameshot = {
    enable = true;
    settings.General = {
      showStartupLaunchMessage = false;
      disabledTrayIcon = true;
      useX11LegacyScreenshot = true;
    };
  };

  programs.home-manager.enable = true; # Let Home Manager install and manage itself.

  # Obsidian: setzt bei jedem Rebuild/Boot "frame":"native" in obsidian.json,
  # damit Obsidian unter qtile keinen eigenen Fensterrahmen/Buttons zeichnet.
  # Nur dieser eine Wert wird geändert, die Vault-Liste bleibt erhalten.
  home.activation.obsidianFrame = lib.hm.dag.entryAfter ["writeBoundary"] ''
    f="$HOME/.config/obsidian/obsidian.json"
    mkdir -p "$(dirname "$f")"
    [ -s "$f" ] || echo '{}' > "$f"
    ${pkgs.jq}/bin/jq '.frame = "native"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  '';

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    shellWrapperName = "y";

    plugins = {
      inherit (pkgs.yaziPlugins) full-border git smart-enter toggle-pane mount;
    };

    initLua = ''
      require("full-border"):setup()
      require("git"):setup()
    '';

    settings = {
      mgr.show_hidden = true;

      opener.pdf = [
        {
          run = "xdg-open %s";
          orphan = true;
          for = "unix";
        }
      ];

      # rmpc ist ein TUI -> block = true, damit es im Yazi-Terminal läuft
      opener.music = [
        {
          run = ''rmpc'';
          block = true;
          desc = "In rmpc-Queue und öffnen";
          for = "unix";
        }
      ];

      open.prepend_rules = [
        {
          mime = "application/pdf";
          use = "pdf";
        }

        {
          mime = "audio/*";
          use = "music";
        }
      ];
    };

    keymap.mgr.prepend_keymap = [
      {
        on = "<Enter>";
        run = "plugin smart-enter";
        desc = "Enter dir or open file";
      }
      {
        on = "l";
        run = "plugin smart-enter";
        desc = "Enter dir or open file";
      }
      {
        on = "T";
        run = "plugin toggle-pane max-preview";
        desc = "Maximize preview";
      }
      {
        on = "M";
        run = "plugin mount";
        desc = "Mount manager";
      }
    ];
  };

  services.mpd = {
    enable = true;
    musicDirectory = "/home/marc/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
      auto_update "yes"
    '';
  };
}
