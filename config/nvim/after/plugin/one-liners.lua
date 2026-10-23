require("lualine").setup({ options = { theme = "tokyonight" } })
require("nvim-highlight-colors").setup({})
require("kitty-scrollback").setup({
    { -- globale Config (erster Eintrag ohne Namen)
        paste_window = { yank_register_enabled = false },
    },
})
