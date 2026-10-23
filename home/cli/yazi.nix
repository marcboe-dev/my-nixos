{
  pkgs,
  lib,
  osConfig,
  ...
}: {
  home.packages = lib.optional (osConfig.my.terminal == "alacritty") pkgs.ueberzugpp;

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
          run = "rmpc";
          block = true;
          desc = "rmpc öffnen";
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
}
