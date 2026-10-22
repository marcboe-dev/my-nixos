{pkgs, ...}: {
  home.packages = with pkgs; [
    ripgrep
    nil
    alejandra #ersetzt nixpkgs-fmt
    clang-tools #clang-d + clang-format
    nodejs
    gcc
    gnumake
    taplo #TOML LSP + formatter
  ];
}
