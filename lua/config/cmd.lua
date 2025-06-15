local utils = require('utils')

local function augroup(name)
  return vim.api.nvim_create_augroup('user ' .. name, { clear = true })
end

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
-- golang develop related
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

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- defaults:
    -- https://neovim.io/doc/user/news-0.11.html#_defaults
    map('gl', vim.diagnostic.open_float, 'Open Diagnostic Float')
    map('K', vim.lsp.buf.hover, 'Hover Documentation')
    map('gs', vim.lsp.buf.signature_help, 'Signature Documentation')
    map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
    map('grn', vim.lsp.buf.rename, 'Rename all references')
    map('<leader>lf', vim.lsp.buf.format, 'Format')
    map(
      '<leader>v',
      '<cmd>vsplit | lua vim.lsp.buf.definition()<cr>',
      'Goto Definition in Vertical Split'
    )

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

      -- Configure diagnostics settings
      vim.diagnostic.config({
        virtual_lines = false,
        underline = false,

        float = {
          show_header = false,
          format = function(diagnostic)
            if diagnostic.code then
              return string.format(
                '%s(%s) - %s',
                diagnostic.source,
                diagnostic.code,
                diagnostic.message
              )
            end
            return string.format('%s - %s', diagnostic.source, diagnostic.message)
          end,
        },
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
