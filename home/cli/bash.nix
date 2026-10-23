{pkgs, ...}: {
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
    '';
  };

  home.packages = with pkgs; [
    bat
    btop
    unrar
  ];

  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
