{pkgs, ...}: {
  home.packages = with pkgs; [
    ripgrep
    nil
    lua-language-server #LSP für Lua
    alejandra #ersetzt nixpkgs-fmt
    clang-tools #clang-d + clang-format
    gdb
    vscode-extensions.vadimcn.vscode-lldb.adapter # codelldb (Debug-Adapter für nvim-dap), liegt als `codelldb` im PATH
    nodejs
    gcc
    gnumake
    taplo #TOML LSP + formatter
  ];
}
