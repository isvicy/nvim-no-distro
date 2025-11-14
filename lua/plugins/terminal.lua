return {
  {
    'NvChad/nvterm',

    keys = {

      {
        '<A-h>',
        function()
          require('nvterm.terminal').toggle('horizontal')
        end,
        mode = { 'n', 't', 'i' },
        desc = 'Toggle Horizontal Terminal',
      },
      {
        '<A-v>',

        function()
          require('nvterm.terminal').toggle('vertical')
        end,

        mode = { 'n', 't', 'i' },
        desc = 'Toggle Vertical Terminal',
      },

      {
        '<A-f>',
        function()
          require('nvterm.terminal').toggle('float')
        end,

        mode = { 'n', 't', 'i' },
        desc = 'Toggle Floating Terminal',
      },
    },
    opts = {},
  },
}
