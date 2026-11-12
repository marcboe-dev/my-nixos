{pkgs, ...}: {
  home.packages = [
    pkgs.tmux
  ];

  xdg.dataFile."tmux/plugins.conf".text = ''
    set -g @resurrect-capture-pane-contents 'on'
    set -g @continuum-restore 'on'
    set -g @resurrect-hook-post-restore-all 'for w in $(tmux list-windows -a -F "#{session_name}:#{window_index}"); do tmux set -w -t "$w" -u automatic-rename; done'
    run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
    run-shell ${pkgs.tmuxPlugins.continuum.rtp}
  '';
}
