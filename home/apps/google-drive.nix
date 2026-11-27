{
  config,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  mountDir = "${home}/GoogleDrive";
in {
  home.packages = [pkgs.rclone];

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
}
