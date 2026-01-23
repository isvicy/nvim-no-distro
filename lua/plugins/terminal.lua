return {
  {
    'isvicy/nvterm',
    keys = {
      -- Per-path terminals (Alt + key)
      {
        '<A-h>',
        function()
          require('nvterm.terminal').toggle_per_path('horizontal')
        end,
        mode = { 'n', 't', 'i' },
        desc = 'Toggle Horizontal Terminal (per-path)',
      },
      {
        '<A-v>',
        function()
          require('nvterm.terminal').toggle_per_path('vertical')
        end,
        mode = { 'n', 't', 'i' },
        desc = 'Toggle Vertical Terminal (per-path)',
      },
      {
        '<A-f>',
        function()
          require('nvterm.terminal').toggle_per_path('float')
        end,
        mode = { 'n', 't', 'i' },
        desc = 'Toggle Floating Terminal (per-path)',
      },

      -- General terminals (Alt + Ctrl + key)
      {
        '<A-C-h>',
        function()
          require('nvterm.terminal').toggle('horizontal')
        end,
        mode = { 'n', 't', 'i' },
        desc = 'Toggle Horizontal Terminal (general)',
      },
      {
        '<A-C-v>',
        function()
          require('nvterm.terminal').toggle('vertical')
        end,
        mode = { 'n', 't', 'i' },
        desc = 'Toggle Vertical Terminal (general)',
      },
      {
        '<A-C-f>',
        function()
          require('nvterm.terminal').toggle('float')
        end,
        mode = { 'n', 't', 'i' },
        desc = 'Toggle Floating Terminal (general)',
      },
    },
    opts = {
      terminals = {
        type_opts = {
          float = {
            -- relative = 'editor',
            -- row = 0.8,
            -- col = 0.8,
            width = 1,
            height = 1,
            border = 'single',
          },
        },
      },
    },
  },
}
