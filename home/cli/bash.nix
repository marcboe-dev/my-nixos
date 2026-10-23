{pkgs, ...}: {
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos-btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
      vi = "nvim";
    };
    initExtra = ''
      PS1_FULL="\[\e[38;5;75m\]\u@\h \[\e[38;5;113m\]\w \[\e[38;5;189m\]\$ \[\e[0m\]"
      PS1_SHORT="\[\e[38;5;189m\]> \[\e[0m\]"
      PS1="$PS1_FULL"
      pt() { if [ "$PS1" = "$PS1_FULL" ]; then PS1="$PS1_SHORT"; else PS1="$PS1_FULL"; fi; }

      export EDITOR=nvim
      export VISUAL=nvim

      export MANPAGER="nvim +Man!"
    '';
  };

  home.packages = with pkgs; [
    bat
    btop
  ];

  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
