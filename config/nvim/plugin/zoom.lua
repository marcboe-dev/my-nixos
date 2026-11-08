-- ─────────────────────────────────────────────────────────────────────
-- Zoom: aktuelles Fenster groß als Float anzeigen
--
-- <leader>z      → Fenster zoomen, nochmal <leader>z → schließen
-- Verlässt man das Float (z. B. mit den Pfeiltasten), schließt es sich.
-- Funktioniert für jedes Fenster: Code, dap-ui-Elemente, REPL, Console …
-- ─────────────────────────────────────────────────────────────────────

local zoom_win = nil
local zoom_group = vim.api.nvim_create_augroup("ZoomFloat", { clear = true })

local function close_zoom()
    if zoom_win and vim.api.nvim_win_is_valid(zoom_win) then
        vim.api.nvim_win_close(zoom_win, true)
    end
    zoom_win = nil
end

local function toggle_zoom()
    if zoom_win and vim.api.nvim_win_is_valid(zoom_win) then
        close_zoom()
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor((vim.o.lines - 2) * 0.85)
    local name = vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "zoom"

    zoom_win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2) - 1,
        col = math.floor((vim.o.columns - width) / 2),
        border = "rounded",
        title = " " .. name .. "   <leader>z = schließen ",
        title_pos = "center",
    })
    pcall(vim.api.nvim_win_set_cursor, zoom_win, cursor)
    vim.wo[zoom_win].wrap = true -- lange Zeilen umbrechen statt abschneiden

    -- Float automatisch schließen, sobald man es verlässt
    vim.api.nvim_clear_autocmds({ group = zoom_group })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = zoom_group,
        once = true,
        callback = function() vim.schedule(close_zoom) end,
    })
end

vim.keymap.set("n", "<leader>z", toggle_zoom, { desc = "Fenster zoomen (Float)" })
