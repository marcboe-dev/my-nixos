{...}: {
  programs.git = {
    enable = true;
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

  # gh: nötig für `gh auth login` und git push zu GitHub
  programs.gh.enable = true;
}
