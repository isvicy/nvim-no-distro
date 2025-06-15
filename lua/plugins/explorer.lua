return {
  'mikavilpas/yazi.nvim',
  event = 'VeryLazy',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    {
      '<leader>fy',

      function()
        require('yazi').yazi()
      end,
      { desc = 'Open yazi file manager' },
    },
  },
  opts = {
    open_for_directories = false,
  },
}
