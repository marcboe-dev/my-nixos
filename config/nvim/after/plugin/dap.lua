-- ─────────────────────────────────────────────────────────────────────
-- Debugging mit nvim-dap + nvim-dap-ui + codelldb
--
-- codelldb kommt aus nixpkgs (home/cli/neovim.nix), NICHT aus Mason.
-- Programme mit Debug-Infos kompilieren:  gcc -g -O0 main.c -o main
-- ─────────────────────────────────────────────────────────────────────

-- Falls die Plugins (noch) nicht geklont sind, nvim nicht crashen lassen
local ok_dap, dap = pcall(require, "dap")
local ok_ui, dapui = pcall(require, "dapui")
if not (ok_dap and ok_ui) then
    vim.notify("nvim-dap / nvim-dap-ui nicht gefunden – Debugging deaktiviert", vim.log.levels.WARN)
    return
end

dapui.setup()

-- ── Adapter ──────────────────────────────────────────────────────────
-- codelldb läuft als Server; nvim-dap sucht selbst einen freien Port.
dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
        command = "codelldb",
        args = { "--port", "${port}" },
    },
}

-- ── Hilfsfunktionen ──────────────────────────────────────────────────
-- Merkt sich das zuletzt gewählte Programm, damit man es nicht jedes
-- Mal neu eintippen muss.
local last_program = nil

local function pick_program()
    if vim.fn.executable("codelldb") ~= 1 then
        vim.notify("codelldb not found in PATH – did you run home-manager switch?", vim.log.levels.ERROR)
        return dap.ABORT
    end

    local default = last_program or (vim.fn.getcwd() .. "/")
    local path = vim.fn.input("Executable: ", default, "file")
    if path == nil or path == "" then
        return dap.ABORT
    end

    path = vim.fn.fnamemodify(path, ":p")
    if vim.fn.executable(path) ~= 1 then
        vim.notify("Not executable: " .. path .. "  (compiled with -g?)", vim.log.levels.ERROR)
        return dap.ABORT
    end

    last_program = path
    return path
end

local function pick_args()
    local input = vim.fn.input("Arguments: ")
    return vim.split(input, " ", { trimempty = true })
end

local configs = {
    {
        name = "Launch",
        type = "codelldb",
        request = "launch",
        program = pick_program,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
        terminal = "integrated",
    },
    {
        name = "Launch with arguments",
        type = "codelldb",
        request = "launch",
        program = pick_program,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = pick_args,
        terminal = "integrated",
    },
    {
        name = "Attach to running process",
        type = "codelldb",
        request = "attach",
        pid = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
    },
}

dap.configurations.c = configs
dap.configurations.cpp = configs
dap.configurations.rust = configs

-- ── UI automatisch öffnen/schließen ──────────────────────────────────
dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

-- ── Zeichen in der Signcolumn ────────────────────────────────────────
vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DapLogPoint", { text = "◉", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

-- ── Quick Debug: aktuelle Datei kompilieren + sofort debuggen ────────
-- debug-counter.c  →  gcc -g -Wall -Wextra debug-counter.c -o debug-counter
local show_warnings = true -- <leader>bW schaltet um (aus = ohne Hinweise üben)

local function quick_debug()
    local ext = vim.fn.expand("%:e")
    if ext ~= "c" and ext ~= "cpp" then
        dap.continue() -- keine C/C++-Datei → normales Launch-Menü
        return
    end

    vim.cmd("silent write")

    local src = vim.fn.expand("%:p")
    local exe = vim.fn.expand("%:p:r")
    local cmd = { (ext == "c") and "gcc" or "g++", "-g", src, "-o", exe }
    if show_warnings then
        table.insert(cmd, 3, "-Wall")
        table.insert(cmd, 4, "-Wextra")
    end

    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        vim.notify("Compile failed:\n" .. out, vim.log.levels.ERROR)
        return
    end
    if show_warnings and out ~= "" then
        vim.notify("Warnings:\n" .. out, vim.log.levels.WARN)
    end

    last_program = exe
    dap.run({
        name = "Quick Debug",
        type = "codelldb",
        request = "launch",
        program = exe,
        cwd = vim.fn.expand("%:p:h"),
        stopOnEntry = false,
        args = {},
        terminal = "integrated",
    })
end

-- F11: keine Session → Quick Debug, sonst → Continue
local function go()
    if dap.session() then
        dap.continue()
    else
        quick_debug()
    end
end

-- ── Keybinds ─────────────────────────────────────────────────────────
-- Steppen auf F-Tasten: ein Tastendruck, funktioniert zuverlässig in
-- kitty, alacritty und tmux
vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
-- F9–F12 liegen wie h j k l:
--   F9  (h, ←)  Step Out   – raus aus der Funktion
--   F10 (j, ↓)  Step Over  – nächste Zeile
--   F11 (k, ↑)  Continue   – los bis zum nächsten Breakpoint / Session starten
--   F12 (l, →)  Step Into  – rein in die Funktion
--   F8          Breakpoint an/aus
vim.keymap.set("n", "<F8>", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
vim.keymap.set("n", "<F9>", dap.step_out, { desc = "Debug: Step Out" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
vim.keymap.set("n", "<F11>", go, { desc = "Debug: Quick Debug / Continue" })
vim.keymap.set("n", "<leader>bm", dap.continue, { desc = "Debug: Launch-Menü (Args, Attach)" })
vim.keymap.set("n", "<leader>bW", function()
    show_warnings = not show_warnings
    vim.notify("Quick Debug Warnungen: " .. (show_warnings and "an" or "aus"))
end, { desc = "Debug: Warnungen an/aus" })
vim.keymap.set("n", "<F12>", dap.step_into, { desc = "Debug: Step Into" })

-- Alles andere unter <leader>b ("bug"). NICHT <leader>d, das ist
-- schon "_d (löschen ohne Register) und würde jedes Mal warten.
vim.keymap.set("n", "<leader>bb", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
vim.keymap.set("n", "<leader>bc", function()
    dap.set_breakpoint(vim.fn.input("Bedingung: "))
end, { desc = "Debug: Conditional Breakpoint" })
vim.keymap.set("n", "<leader>bl", function()
    dap.set_breakpoint(nil, nil, vim.fn.input("Log-Nachricht: "))
end, { desc = "Debug: Logpoint" })
vim.keymap.set("n", "<leader>bx", dap.clear_breakpoints, { desc = "Debug: Alle Breakpoints löschen" })
vim.keymap.set("n", "<leader>br", dap.run_last, { desc = "Debug: Letzte Session neu starten" })
vim.keymap.set("n", "<leader>bC", dap.run_to_cursor, { desc = "Debug: Bis zum Cursor laufen" })
vim.keymap.set("n", "<leader>bq", dap.terminate, { desc = "Debug: Session beenden" })
vim.keymap.set("n", "<leader>bu", dapui.toggle, { desc = "Debug: UI ein/aus" })
vim.keymap.set({ "n", "v" }, "<leader>be", function() dapui.eval() end, { desc = "Debug: Ausdruck auswerten" })
vim.keymap.set("n", "<leader>bE", function()
    dapui.eval(nil, { enter = true })
end, { desc = "Debug: Auswerten + in Float springen" })
