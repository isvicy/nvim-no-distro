-- Trigger character for snippets (type ;snippet_name to trigger)
local trigger_text = ';'

return {
  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'InsertEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = 'v2.*',
        build = (function()
          if vim.fn.has('win32') == 1 or vim.fn.executable('make') == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          {
            'rafamadriz/friendly-snippets',
            config = function()
              require('luasnip.loaders.from_vscode').lazy_load()
            end,
          },
        },
        opts = {},
      },
      'folke/lazydev.nvim',
      'kristijanhusak/vim-dadbod-completion',
      'Kaiser-Yang/blink-cmp-dictionary',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default',
        ['<Tab>'] = { 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<C-n>'] = { 'select_next', 'fallback' },

        ['<S-k>'] = { 'scroll_documentation_up', 'fallback' },
        ['<S-j>'] = { 'scroll_documentation_down', 'fallback' },

        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide', 'fallback' },
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = {
        menu = {
          border = 'single',
        },
        documentation = {
          auto_show = true,
          window = {
            border = 'single',
          },
        },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'dadbod', 'dictionary' },
        per_filetype = {
          sql = { 'dadbod' },
          lua = { inherit_defaults = true, 'lazydev' },
        },
        providers = {
          lsp = {
            name = 'lsp',
            enabled = true,
            module = 'blink.cmp.sources.lsp',
            kind = 'LSP',
            min_keyword_length = 0,
            score_offset = 90, -- highest priority
          },
          path = {
            name = 'Path',
            module = 'blink.cmp.sources.path',
            score_offset = 25,
            fallbacks = { 'snippets', 'buffer' },
            opts = {
              trailing_slash = false,
              label_trailing_slash = true,
              get_cwd = function(context)
                return vim.fn.expand(('#%d:p:h'):format(context.bufnr))
              end,
              show_hidden_files_by_default = true,
            },
          },
          buffer = {
            name = 'Buffer',
            enabled = true,
            max_items = 3,
            module = 'blink.cmp.sources.buffer',
            min_keyword_length = 2,
            score_offset = 15,
          },
          snippets = {
            name = 'snippets',
            enabled = true,
            max_items = 15,
            min_keyword_length = 2,
            module = 'blink.cmp.sources.snippets',
            score_offset = 85,
            -- Only show snippets if I type the trigger_text characters
            -- To expand the "bash" snippet, type ";bash"
            should_show_items = function()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = vim.api.nvim_get_current_line():sub(1, col)
              return before_cursor:match(trigger_text .. '%w*$') ~= nil
            end,
            -- After accepting the completion, delete the trigger_text characters
            transform_items = function(_, items)
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              local start_pos, end_pos = before_cursor:find(trigger_text .. '[^' .. trigger_text .. ']*$')
              if start_pos then
                for _, item in ipairs(items) do
                  if not item.trigger_text_modified then
                    ---@diagnostic disable-next-line: inject-field
                    item.trigger_text_modified = true
                    item.textEdit = {
                      newText = item.insertText or item.label,
                      range = {
                        start = { line = vim.fn.line('.') - 1, character = start_pos - 1 },
                        ['end'] = { line = vim.fn.line('.') - 1, character = end_pos },
                      },
                    }
                  end
                end
              end
              return items
            end,
          },
          dadbod = {
            name = 'Dadbod',
            module = 'vim_dadbod_completion.blink',
            min_keyword_length = 2,
            score_offset = 85,
          },
          lazydev = {
            module = 'lazydev.integrations.blink',
            score_offset = 90,
          },
          -- https://github.com/Kaiser-Yang/blink-cmp-dictionary
          -- Requires fzf to be installed
          dictionary = {
            module = 'blink-cmp-dictionary',
            name = 'Dict',
            score_offset = 20,
            enabled = true,
            max_items = 8,
            min_keyword_length = 3,
            opts = {
              -- Dictionary directory containing .txt files
              dictionary_directories = { vim.fn.stdpath('config') .. '/dictionaries' },
              -- Also include spell dictionary for custom words
              dictionary_files = {
                vim.fn.stdpath('config') .. '/spell/en.utf-8.add',
              },
            },
          },
        },
      },

      cmdline = {
        enabled = true,
      },

      snippets = { preset = 'luasnip' },

      fuzzy = {
        implementation = 'rust',
      },

      signature = { enabled = true },
    },
  },
}
