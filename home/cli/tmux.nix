{pkgs, ...}: {
  home.packages = [pkgs.tmux];

  xdg.dataFile."tmux/plugins.conf".text = ''
    set -g @resurrect-capture-pane-contents 'on'
    set -g @continuum-restore 'on'
    run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
    run-shell ${pkgs.tmuxPlugins.continuum.rtp}
  '';
}
