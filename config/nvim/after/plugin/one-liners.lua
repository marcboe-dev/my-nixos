require("lualine").setup({ options = { theme = "tokyonight" } })
require("nvim-highlight-colors").setup({})
require("kitty-scrollback").setup({
    {     -- globale Config (erster Eintrag ohne Namen)
        paste_window = { yank_register_enabled = false },
        callbacks = {
            -- läuft nur in der Scrollback-Instanz, dein normales nvim bleibt unberührt
            after_ready = function()
                vim.keymap.set({ "n", "x" }, "y", '"+y', {
                    desc = "Yank ins Clipboard & zurück zu Kitty",
                })
            end,
        },
    },
})
