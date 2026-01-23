return {
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      -- Remove a,i,o,r,x from labels to avoid conflicts with vim operators
      labels = 'fghjklqwetyupzcvbnm',
      search = {
        -- Use "search" mode instead of "exact" - if you mistype, flash won't exit
        -- This prevents accidental insertions when you mistype during flash
        mode = 'search',
      },
      modes = {
        search = {
          enabled = false,
        },
        char = {
          -- Disable f/t/F/T flash enhancement
          enabled = false,
        },
      },
      label = {
        after = { 0, 2 },
      },
    },
    keys = {
      {
        's',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash',
      },
      {
        'S',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
      {
        'r',
        mode = 'o',
        function()
          require('flash').remote()
        end,
        desc = 'Remote Flash',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter_search()
        end,
        desc = 'Treesitter Search',
      },
      {
        '<c-s>',
        mode = { 'c' },
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle Flash Search',
      },
    },
  },
}
