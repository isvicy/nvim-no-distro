local utils = require('utils')

local function augroup(name)
  return vim.api.nvim_create_augroup('user ' .. name, { clear = true })
end

-- Clear jumps when opening Neovim to avoid old jump history clutter
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = augroup('clear_jumps'),
  once = true,
  callback = function()
    vim.schedule(function()
      vim.cmd('clearjumps')
    end)
  end,
})

-- Enable spell checking for text-based file types
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('wrap_spell'),
  pattern = { 'text', 'plaintex', 'typst', 'gitcommit' },
  callback = function()
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    vim.opt_local.formatoptions:remove({ 'c', 'r', 'o' })
  end,
})

-- auto open fzf-lua when opening a directory
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function(data)
    -- buffer is a directory

    local directory = vim.fn.isdirectory(data.file) == 1

    -- change to the directory
    if directory then
      local opts = { cwd = data.file }
      local builtin
      if vim.uv.fs_stat((opts.cwd or vim.loop.cwd()) .. '/.git') then
        opts.show_untracked = true
        builtin = 'git_files'
      else
        builtin = 'files'
      end
      require('fzf-lua')[builtin](opts)
    end
  end,
  group = augroup('find files'),
  desc = 'open Telescope when opening a dir',
})

-- Register user commands
vim.api.nvim_create_user_command('PrintFullPath', utils.print_full_path, {})
vim.api.nvim_create_user_command('DBUIPrompt', utils.prompt_db_connection, {})
-- Golang develop related
vim.api.nvim_create_user_command('GoBuild', utils.async_go_build_quickfix, {})
vim.api.nvim_create_user_command('CopyDiagnostic', utils.copy_diagnostic, {})
vim.api.nvim_create_user_command('GoDebugSetup', utils.setup_go_debug_config, {})
-- general tricks
vim.api.nvim_create_user_command('DiffViewLineCommit', function()
  utils.open_line_commit_diffview()
end, {})

-- Register keymaps

vim.keymap.set('n', '<Leader>cgb', ':GoBuild<CR>', { silent = true, noremap = true })
vim.keymap.set('n', '<leader>ccd', function()
  utils.copy_diagnostic()
end, {
  silent = true,
  desc = 'Copy diagnostic message',
})
vim.keymap.set(
  'n',
  '<leader>cds',
  utils.setup_go_debug_config,
  { desc = 'Setup Go Debug Configuration' }
)
vim.keymap.set(
  'n',
  '<leader>gld',
  utils.open_line_commit_diffview,
  { noremap = true, silent = true, desc = '查看当前行的 commit diff' }
)

-- LspAttach events
-- create a split to go to definition
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function()
    local opts = { noremap = true, silent = true }
    vim.keymap.set('n', '<leader>v', function()
      vim.cmd('vsp')
      vim.lsp.buf.definition()
      vim.defer_fn(function()
        vim.cmd('normal! zz')
      end, 10) -- Delay in milliseconds
    end, opts)
  end,
  group = augroup('go to definition split'),
  desc = 'go to definition in a split',
})
-- create keymaps for LSP
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- LSP keymaps
    map(
      'gd',
      '<cmd>FzfLua lsp_definitions jump1=true ignore_current_line=true<cr>',
      'Goto Definition'
    )
    map('gr', '<cmd>FzfLua lsp_references jump1=true ignore_current_line=true<cr>', 'References')
    map(
      'gI',
      '<cmd>FzfLua lsp_implementations jump1=true ignore_current_line=true<cr>',
      'Goto Implementation'
    )
    map(
      'gy',
      '<cmd>FzfLua lsp_typedefs jump1=true ignore_current_line=true<cr>',
      'Goto Type Definition'
    )
    map('gl', vim.diagnostic.open_float, 'Open Diagnostic Float')
    map('K', vim.lsp.buf.hover, 'Hover Documentation')
    map('<leader>cr', vim.lsp.buf.rename, 'Rename all references')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
    map('<leader>cf', vim.lsp.buf.format, 'Format')
    map('<leader>bf', '<cmd>FzfLua lsp_document_symbols<cr>', 'find symbols in buffer')

    local function client_supports_method(client, method, bufnr)
      if vim.fn.has('nvim-0.11') == 1 then
        return client:supports_method(method, bufnr)
      else
        return client.supports_method(method, { bufnr = bufnr })
      end
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if
      client
      and client_supports_method(
        client,
        vim.lsp.protocol.Methods.textDocument_documentHighlight,
        event.buf
      )
    then
      local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
      -- When cursor stops moving: Highlights all instances of the symbol under the cursor
      -- When cursor moves: Clears the highlighting
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      -- When LSP detaches: Clears the highlighting
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({ group = 'lsp-highlight', buffer = event2.buf })
        end,
      })
    end
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Setup render-markdown highlights for specific colorschemes
vim.api.nvim_create_autocmd('ColorScheme', {
  group = augroup('markdown-highlights'),
  callback = function()
    local colorscheme = vim.g.colors_name or ''
    local heading_colors, heading_bg, code_bg, checked_fg, unchecked_fg

    if colorscheme:match('vesper') then
      -- vesper: 使用主题真实调色板
      heading_colors = {
        '#FFC799', -- H1: yellowDark (橙黄)
        '#99FFE4', -- H2: green/greenLight (青绿)
        '#FFCFA8', -- H3: orange (橙色)
        '#FF8080', -- H4: red (红色)
        '#A0A0A0', -- H5: primary (灰色)
        '#65737E', -- H6: symbol (深灰)
      }
      heading_bg = '#161616' -- bgDark
      code_bg = '#232323' -- bgDarker
      checked_fg = '#99FFE4' -- green
      unchecked_fg = '#505050' -- fgDisabled
    elseif colorscheme:match('tundra') then
      -- tundra (arctic): 使用主题真实调色板
      heading_colors = {
        '#BAE6FD', -- H1: sky._500 (天蓝)
        '#B5E8B0', -- H2: green._500 (绿色)
        '#A5B4FC', -- H3: indigo._500 (靛蓝)
        '#FBC19D', -- H4: orange._500 (橙色)
        '#FCA5A5', -- H5: red._500 (红色)
        '#99BBBD', -- H6: opal._500 (青灰)
      }
      heading_bg = '#1F2937' -- gray._800
      code_bg = '#1F2937' -- gray._800
      checked_fg = '#B5E8B0' -- green._500
      unchecked_fg = '#4B5563' -- gray._600
    else
      -- 默认: 保持简单
      return
    end

    for i, color in ipairs(heading_colors) do
      vim.api.nvim_set_hl(0, '@markup.heading.' .. i .. '.markdown', {
        fg = color,
        bold = true,
      })
      vim.api.nvim_set_hl(0, 'RenderMarkdownH' .. i, { fg = color, bold = true })
      vim.api.nvim_set_hl(0, 'RenderMarkdownH' .. i .. 'Bg', { bg = heading_bg })
    end

    vim.api.nvim_set_hl(0, 'RenderMarkdownChecked', { fg = checked_fg })
    vim.api.nvim_set_hl(0, 'RenderMarkdownUnchecked', { fg = unchecked_fg })
    vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = code_bg })
  end,
})

-- Trigger for initial colorscheme
vim.api.nvim_exec_autocmds('ColorScheme', {})

-------------------------------------------------------------------------------
--                           Markdown Folding
-------------------------------------------------------------------------------

-- Build code block ranges using treesitter (called once per buffer)
local function build_code_block_ranges(bufnr)
  local ranges = {}
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'markdown')
  if not ok or not parser then
    return ranges
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return ranges
  end

  for _, tree in ipairs(trees) do
    local root = tree:root()
    -- Query for fenced_code_block nodes
    local query_ok, query =
      pcall(vim.treesitter.query.parse, 'markdown', '(fenced_code_block) @block')
    if query_ok then
      for _, node in query:iter_captures(root, bufnr, 0, -1) do
        local start_row, _, end_row, _ = node:range()
        table.insert(ranges, { start_row + 1, end_row + 1 }) -- 1-indexed
      end
    end
  end
  return ranges
end

-- Check if line is in any cached code block range
local function is_in_code_block_cached(lnum)
  local ranges = vim.b.code_block_ranges or {}
  for _, range in ipairs(ranges) do
    if lnum >= range[1] and lnum <= range[2] then
      return true
    end
  end
  return false
end

-- Custom fold expression: fold based on heading level (#, ##, ###...)
function _G.markdown_foldexpr()
  local lnum = vim.v.lnum

  -- Skip lines inside code blocks (using cached ranges)
  if is_in_code_block_cached(lnum) then
    return '='
  end

  local line = vim.fn.getline(lnum)
  local heading = line:match('^(#+)%s')
  if heading then
    local level = #heading
    if level == 1 then
      -- H1 only valid at line 1 or after frontmatter
      if lnum == 1 then
        return '>1'
      end
      local frontmatter_end = vim.b.frontmatter_end
      if frontmatter_end and (lnum == frontmatter_end + 1) then
        return '>1'
      end
      -- Otherwise, ignore H1 (likely inside code block or other context)
      return '='
    elseif level >= 2 and level <= 6 then
      return '>' .. level
    end
  end
  return '='
end

-- Set markdown folding options
local function set_markdown_folding()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Build and cache code block ranges
  vim.b.code_block_ranges = build_code_block_ranges(bufnr)

  vim.opt_local.foldmethod = 'expr'
  vim.opt_local.foldexpr = 'v:lua.markdown_foldexpr()'
  vim.opt_local.foldlevel = 99 -- Start with all folds open

  -- Detect frontmatter closing line (for H1 handling)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local found_first = false
  for i, line in ipairs(lines) do
    if line == '---' then
      if not found_first then
        found_first = true
      else
        vim.b.frontmatter_end = i
        break
      end
    end
  end
end

-- Apply folding settings to markdown files
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('markdown-folding'),
  pattern = 'markdown',
  callback = set_markdown_folding,
})

-- Fold all headings of a specific level
local function fold_headings_of_level(level)
  vim.cmd('keepjumps normal! gg')
  local total_lines = vim.fn.line('$')
  for line = 1, total_lines do
    local line_content = vim.fn.getline(line)
    if line_content:match('^' .. string.rep('#', level) .. '%s') then
      -- Skip headings inside code blocks (using cached ranges)
      if not is_in_code_block_cached(line) then
        vim.cmd(string.format('keepjumps call cursor(%d, 1)', line))
        if vim.fn.foldlevel(line) > 0 and vim.fn.foldclosed(line) == -1 then
          vim.cmd('normal! za')
        end
      end
    end
  end
end

-- Fold multiple heading levels
local function fold_markdown_headings(levels)
  local saved_view = vim.fn.winsaveview()
  for _, level in ipairs(levels) do
    fold_headings_of_level(level)
  end
  vim.cmd('nohlsearch')
  vim.fn.winrestview(saved_view)
end

-- Keymaps for folding (only in markdown files)
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('markdown-fold-keymaps'),
  pattern = 'markdown',
  callback = function()
    local opts = { buffer = true, silent = true }

    -- Toggle fold with Enter
    vim.keymap.set('n', '<CR>', function()
      if vim.fn.foldlevel('.') > 0 then
        vim.cmd('normal! za')
      end
    end, vim.tbl_extend('force', opts, { desc = 'Toggle fold' }))

    -- zk: Fold all H2+ headings
    vim.keymap.set('n', 'zk', function()
      vim.cmd('silent update')
      -- Refresh code block ranges cache
      vim.b.code_block_ranges = build_code_block_ranges(vim.api.nvim_get_current_buf())
      vim.cmd('edit!')
      vim.cmd('normal! zR')
      fold_markdown_headings({ 6, 5, 4, 3, 2 })
      vim.cmd('normal! zz')
    end, vim.tbl_extend('force', opts, { desc = 'Fold H2+ headings' }))

    -- zu: Unfold all
    vim.keymap.set('n', 'zu', function()
      vim.cmd('silent update')
      vim.cmd('normal! zR')
    end, vim.tbl_extend('force', opts, { desc = 'Unfold all' }))
  end,
})

-- Auto fold H2+ headings when opening markdown files
vim.api.nvim_create_autocmd('BufRead', {
  group = augroup('markdown-auto-fold'),
  pattern = '*.md',
  callback = function()
    if vim.b.auto_folded then
      return
    end
    vim.b.auto_folded = true
    vim.defer_fn(function()
      vim.cmd('normal zk')
    end, 100)
  end,
})
