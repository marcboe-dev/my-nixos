{pkgs, ...}: {
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos-btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
      vi = "nvim";

      tn = ''tmux new-session -A -s "$(basename "$PWD" | tr .: __)"'';
      ta = "tmux attach"; # zurück zur zuletzt benutzten Session
      tk = "tmux kill-session -t"; # tk c_programming
      tkill = "tmux kill-server; rm -f ~/.local/share/tmux/resurrect/last";
    };
    initExtra = ''
      PS1_FULL="\[\e]133;A\a\]\[\e[38;5;75m\]\u@\h \[\e[38;5;113m\]\w \[\e[38;5;189m\]\$ \[\e[0m\]"
      PS1_SHORT="\[\e]133;A\a\]\[\e[38;5;189m\]> \[\e[0m\]"
      PS0="\e]133;C\a"
      PS1="$PS1_FULL"
      pt() { if [ "$PS1" = "$PS1_FULL" ]; then PS1="$PS1_SHORT"; else PS1="$PS1_FULL"; fi; }

      export EDITOR=nvim
      export VISUAL=nvim

      export MANPAGER="nvim +Man!"

      # Cheatsheets: cs [-e] [name] [suchbegriff]
      _cs_dir="$HOME/.config/cheatsheets"
      _cs_list() {
        local f
        for f in "$_cs_dir"/*.md; do [ -e "$f" ] && basename "$f" .md; done
      }
      _cs_pick() {
        _cs_list | fzf --prompt="cheatsheet> " \
          --preview "bat --color=always --style=plain -l md $_cs_dir/{}.md"
      }
      cs() {
        local name
        if [ "$1" = "-e" ]; then
          name="''${2:-$(_cs_pick)}"
          [ -n "$name" ] && "$EDITOR" "$_cs_dir/$name.md"
          return
        fi
        name="''${1:-$(_cs_pick)}"
        [ -z "$name" ] && return
        if [ ! -f "$_cs_dir/$name.md" ]; then
          echo "cs: kein Cheatsheet '$name' (anlegen mit: cs -e $name)" >&2
          return 1
        fi
        if [ -n "$2" ]; then
          grep -i -- "$2" "$_cs_dir/$name.md" | bat --style=plain -l md
        else
          bat --style=plain -l md "$_cs_dir/$name.md"
        fi
      }
      _cs_complete() {
        local cur="''${COMP_WORDS[COMP_CWORD]}"
        if [ "$COMP_CWORD" -eq 1 ]; then
          mapfile -t COMPREPLY < <(compgen -W "-e $(_cs_list)" -- "$cur")
        elif [ "$COMP_CWORD" -eq 2 ] && [ "''${COMP_WORDS[1]}" = "-e" ]; then
          mapfile -t COMPREPLY < <(compgen -W "$(_cs_list)" -- "$cur")
        fi
      }
      complete -F _cs_complete cs
    '';
  };

  home.packages = with pkgs; [
    bat
    btop
  ];

  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
