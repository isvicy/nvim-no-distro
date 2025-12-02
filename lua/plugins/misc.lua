return {
  {
    'isvicy/codesnap.nvim',
    build = 'make build_generator',
    cmd = { 'CodeSnap', 'CodeSnapHighlight', 'CodeSnapSave' },
    keys = {
      {
        '<leader>ccc',
        '<cmd>CodeSnap<cr>',
        mode = 'x',
        desc = 'Save selected code snapshot into clipboard',
      },
      {
        '<leader>cs',
        '<cmd>CodeSnapSave<cr>',
        mode = 'x',
        desc = 'Save selected code snapshot in ~/Pictures',
      },
    },
    config = function()
      local theme_map = {
        vesper = { theme = 'vesper', bg_color = '#232323', editor_bg_color = '#101010' },
        tundra = { theme = 'tundra', bg_color = '#1f2937', editor_bg_color = '#111827' },
      }

      local function update_codesnap_theme()
        local colorscheme = vim.g.colors_name
        local mapping = theme_map[colorscheme]
        if mapping then
          local static = require('codesnap.static')
          static.config.theme = mapping.theme
          static.config.bg_color = mapping.bg_color
          static.config.editor_bg_color = mapping.editor_bg_color
        end
      end

      require('codesnap').setup({
        save_path = '~/Pictures',
        has_breadcrumbs = true,
        theme = 'vesper',
        bg_color = '#232323',
        editor_bg_color = '#101010',
        bg_x_padding = 32,
        bg_y_padding = 24,
        watermark = '',
      })

      -- Set initial theme based on current colorscheme
      update_codesnap_theme()

      -- Listen for colorscheme changes
      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = update_codesnap_theme,
      })
    end,
  },
  {
    'stevearc/aerial.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      {
        '<leader>co',
        function()
          require('aerial').fzf_lua_picker()
        end,
        mode = 'n',
        desc = 'searching outline',
      },
    },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
  },
  {
    'tpope/vim-abolish',
  },
}
