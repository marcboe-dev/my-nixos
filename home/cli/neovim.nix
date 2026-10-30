{pkgs, ...}: {
  home.packages = with pkgs; [
    ripgrep
    nil
    lua-language-server #LSP für Lua
    alejandra #ersetzt nixpkgs-fmt
    clang-tools #clang-d + clang-format
    gdb
    nodejs
    gcc
    gnumake
    taplo #TOML LSP + formatter
  ];
}
