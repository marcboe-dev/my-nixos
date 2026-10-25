{pkgs, ...}: {
  home.packages = [
    pkgs.tmux

    # Startet tmux (→ continuum stellt Sessions wieder her) und hängt sich
    # an die zuletzt aktive Session an. Wird von nirinit beim Login benutzt.
    (pkgs.writeShellApplication {
      name = "tmux-attach-last";
      runtimeInputs = with pkgs; [tmux coreutils gawk];
      text = ''
        last="''${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last"
        target=""
        if [ -f "$last" ]; then
          target="$(awk -F'\t' '$1 == "state" { print $2 }' "$last")"
        fi

        # Kein Server da → starten; tmux.conf lädt continuum, das im
        # Hintergrund wiederherstellt. Bis zu 5 s darauf warten.
        if ! tmux has-session 2>/dev/null; then
          tmux new-session -d -s _boot
          for _ in $(seq 50); do
            if [ -n "$target" ]; then
              tmux has-session -t "=$target" 2>/dev/null && break
            else
              [ "$(tmux list-sessions | wc -l)" -gt 1 ] && break
            fi
            sleep 0.1
          done
        fi

        # Hilfs-Session wieder entfernen, sobald echte Sessions da sind
        if [ "$(tmux list-sessions | wc -l)" -gt 1 ]; then
          tmux kill-session -t "=_boot" 2>/dev/null || true
        fi

        if [ -n "$target" ] && tmux has-session -t "=$target" 2>/dev/null; then
          exec tmux attach -t "=$target"
        fi
        exec tmux attach
      '';
    })
  ];

  xdg.dataFile."tmux/plugins.conf".text = ''
    set -g @resurrect-capture-pane-contents 'on'
    set -g @continuum-restore 'on'
    run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
    run-shell ${pkgs.tmuxPlugins.continuum.rtp}
  '';
}
