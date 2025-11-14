return {
  {
    'mistricky/codesnap.nvim',
    build = 'make build_generator',
    cmd = { 'CodeSnap', 'CodeSnapHighlight' },
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
    opts = {
      save_path = '~/Pictures',
      has_breadcrumbs = true,
      bg_color = '#535c68',
      watermark = '',
    },
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
}
