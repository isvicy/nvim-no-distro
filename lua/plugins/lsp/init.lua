vim.lsp.enable({
  'gopls',
  'lua_ls',
  'ty',
})

return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {

    'dnlhc/glance.nvim',
    event = 'LspAttach',
    keys = {
      { '<leader>gd', '<cmd>Glance definitions<cr>', desc = 'have a glance at definition' },
      { '<leader>gr', '<cmd>Glance references<cr>', desc = 'have a glance at references' },
      {
        '<leader>gi',
        '<cmd>Glance implementations<cr>',
        desc = 'have a glance at implementations',
      },
    },

    config = function()
      local glance = require('glance')

      local actions = glance.actions
      ---@diagnostic disable: missing-fields
      glance.setup({
        border = {
          enable = true, -- Show window borders. Only horizontal borders allowed

          top_char = '―',
          bottom_char = '―',
        },
        mappings = {
          list = {
            ['<leader>p'] = actions.enter_win('preview'), -- Focus preview window
          },
        },
        hooks = {
          before_open = function(results, open, jump, _)
            local uri = vim.uri_from_bufnr(0)
            if #results == 1 then
              local target_uri = results[1].uri or results[1].targetUri

              if target_uri == uri then
                jump(results[1])
              else
                open(results)
              end
            else
              open(results)
            end
          end,
        },
      })
    end,
  },
  {
    'utilyre/barbecue.nvim',
    name = 'barbecue',
    version = '*',
    event = 'LspAttach',
    dependencies = {
      'SmiteshP/nvim-navic',
      'nvim-tree/nvim-web-devicons', -- optional dependency
    },
    opts = {
      -- configurations go here
    },
    config = function()
      require('barbecue').setup({
        create_autocmd = false, -- prevent barbecue from updating itself automatically
      })

      vim.api.nvim_create_autocmd({
        'WinScrolled', -- or WinResized on NVIM-v0.9 and higher
        'BufWinEnter',
        'CursorHold',
        'InsertLeave',

        -- include this if you have set `show_modified` to `true`
        -- "BufModifiedSet",
      }, {
        group = vim.api.nvim_create_augroup('barbecue.updater', {}),
        callback = function()
          require('barbecue.ui').update()
        end,
      })
    end,
  },
  -- lsp preview
  {
    'rmagatti/goto-preview',
    event = 'LspAttach',
    -- stylua: ignore
    keys = {
      { "gpd", function() require("goto-preview").goto_preview_definition({}) end, desc = "preview definition in float window" },
      { "gpi", function() require("goto-preview").goto_preview_implementation({}) end, desc = "preview implementation in float window" },
      { "gpr", function() require("goto-preview").goto_preview_references() end, desc = "preview references in float window" },
      { "gP", function() require("goto-preview").close_all_win() end, desc = "close all preview windows" },
    },
    opts = {},
  },
  {
    'dgagn/diagflow.nvim',
    event = 'LspAttach',
    opts = function()
      vim.diagnostic.config({
        virtual_text = false,

        virtual_lines = true,
      })
      return {

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
        toggle_event = { 'InsertEnter' },
        scope = 'line',
      }
    end,
  },
}
