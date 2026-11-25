vim.g.maplocalleader = " "          -- VimTeX-Mappings: <Space>ll  <Space>lv  <Space>lc ...
vim.g.vimtex_view_method = "sioyek" -- PDF-Viewer mit Vorwärts-/Rückwärtssuche
vim.g.vimtex_quickfix_mode = 0      -- Fehlerfenster nicht automatisch aufpoppen

-- <Space>li gehört meiner LSP-Info (keybinds.lua), nicht :VimtexInfo
vim.g.vimtex_mappings_disable = { n = { "<localleader>li" } }
