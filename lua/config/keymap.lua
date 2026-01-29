---Set keymap with consistent defaults
---@param mode string|string[] Mode(s) for the keymap
---@param lhs string Left-hand side key combination
---@param rhs string|function Right-hand side command or function
---@param opts table|nil Optional keymap options
local function keymap_set(mode, lhs, rhs, opts)
  local default_opts = { silent = true }
  local final_opts = opts and vim.tbl_extend('force', default_opts, opts) or default_opts
  vim.keymap.set(mode, lhs, rhs, final_opts)
end

-- Insert mode navigation
keymap_set('i', '<C-a>', '<C-o>0')
keymap_set('i', '<C-e>', '<C-o>$')

-- Improved yank behavior
keymap_set('n', 'Y', 'y$')

-- Center search results
keymap_set('n', 'n', 'nzzzv')
keymap_set('n', 'N', 'Nzzzv')
keymap_set('n', 'J', 'mzJ`z')

-- Breaking undo points
keymap_set('i', ',', ',<c-g>u')
keymap_set('i', '.', '.<c-g>u')

-- Paste last yanked text (not deleted)
keymap_set('n', '<leader>P', '"0P')
keymap_set('n', '<leader>p', '"0p')

-- Quick return to normal mode from terminal
keymap_set('t', '<esc>', '<C-\\><C-n>')

-- Better visual mode indenting
keymap_set('v', '<', '<gv')

keymap_set('v', '>', '>gv')

-- Window resizing with arrow keys
keymap_set('n', '<Left>', ':vertical resize +1<CR>')
keymap_set('n', '<Right>', ':vertical resize -1<CR>')
keymap_set('n', '<Up>', ':resize -1<CR>')
keymap_set('n', '<Down>', ':resize +1<CR>')

-- Move to window using the <ctrl> hjkl keys
keymap_set('n', '<C-h>', '<C-w>h', { desc = 'Go to Left Window' })
keymap_set('n', '<C-j>', '<C-w>j', { desc = 'Go to Lower Window' })
keymap_set('n', '<C-k>', '<C-w>k', { desc = 'Go to Upper Window' })
keymap_set('n', '<C-l>', '<C-w>l', { desc = 'Go to Right Window' })

-- Disable builtin keyword completion
keymap_set('i', '<c-p>', '<nop>')
keymap_set('i', '<c-n>', '<nop>')

-- Support for Linux classic move shortcuts
keymap_set('i', '<C-a>', '<C-o>0')
keymap_set('i', '<C-e>', '<C-o>$')

-- Highlight current word under cursor without jumping
keymap_set('n', '*', function()
  vim.cmd.normal({ '*N', bang = true })
end, { desc = 'Highlight word without jumping' })

-- LSP defaults:
-- https://neovim.io/doc/user/news-0.11.html#_defaults
-- remove defaulty keymaps
vim.keymap.del('n', 'grr')
vim.keymap.del('n', 'gra')
vim.keymap.del('n', 'grn')
vim.keymap.del('n', 'gri')
vim.keymap.del('n', 'gO')
vim.keymap.del('i', '<C-S>')
