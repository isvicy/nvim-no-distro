vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.shell = 'zsh'

-- better diff view, see: https://github.com/neovim/neovim/pull/14537
vim.opt.diffopt:append('linematch:50')

-- don't display tab chars in ui
vim.opt.list = false

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`

vim.opt.confirm = true

vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 2 -- Number of spaces tabs count for
vim.opt.shiftround = true -- Round indent
vim.opt.shiftwidth = 2 -- Size of an indent

vim.opt.wrap = false

-- Make sure only one global statusline is used
vim.opt.laststatus = 3

vim.opt.foldcolumn = '0' -- '0' is not bad
vim.opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldmethod = 'expr'
vim.opt.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- Use custom fold text with treesitter syntax highlighting
vim.opt.foldtext = 'v:lua.require("utils.fold").custom_foldtext()'

-- Spell checking: set language to English
-- Use `zg` to add word to dictionary, `zw` to mark as wrong
-- Use `]s` / `[s` to navigate between misspelled words
vim.opt.spelllang = { 'en' }
