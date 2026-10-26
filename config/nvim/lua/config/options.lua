-- OPTIONS
local set = vim.opt

--line nums
set.relativenumber = true
set.number = true

-- indentation and tabs
set.tabstop = 4
set.shiftwidth = 4
set.autoindent = true
set.expandtab = true

-- search settings
set.ignorecase = true
set.smartcase = true

-- appearance
set.termguicolors = true
set.background = "dark"
set.signcolumn = "yes"

-- cursor line
set.cursorline = true

-- 80th column
set.colorcolumn = "80"

-- clipboard
set.clipboard:append("unnamedplus")

-- backspace
set.backspace = "indent,eol,start"

-- split windows
set.splitbelow = true
set.splitright = true

-- dw/diw/ciw works on full-word
set.iskeyword:append("-")

-- keep cursor at least 8 rows from top/bot
set.scrolloff = 8

-- undo dir settings
set.swapfile = false
set.backup = false
set.undodir = os.getenv("HOME") .. "/.vim/undodir"
set.undofile = true

-- incremental search
set.incsearch = true

-- faster cursor hold
set.updatetime = 50

-- Nach dem Öffnen einer Web-URL das Brave-Fenster in niri fokussieren
local function focus_brave()
    if not vim.env.NIRI_SOCKET then return end -- nur unter niri (nicht qtile)
    vim.system({ "niri", "msg", "--json", "windows" }, { text = true }, function(res)
        if res.code ~= 0 then return end
        local id
        for _, w in ipairs(vim.json.decode(res.stdout)) do
            if (w.app_id or ""):match("^brave%-browser$") then id = w.id end
        end
        if id then
            vim.system({ "niri", "msg", "action", "focus-window", "--id", tostring(id) })
        end
    end)
end

vim.ui._orig_open = vim.ui._orig_open or vim.ui.open -- schützt vor doppeltem Wrappen bei <leader>rl
vim.ui.open = function(path, opt)
    local cmd, err = vim.ui._orig_open(path, opt)
    if cmd and type(path) == "string" and path:match("^https?://") then
        vim.defer_fn(focus_brave, 300)
    end
    return cmd, err
end
