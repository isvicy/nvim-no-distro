return {
  {
    'ojroques/nvim-osc52',
    keys = {
      {
        '<leader>y',
        function()
          require('osc52').copy_visual()
        end,
        desc = 'copy select section',
        mode = 'x',
      },
    },
    opts = {
      max_length = 0, -- Maximum length of selection (0 for no limit)
      silent = false, -- Disable message on successful copy
      trim = false, -- Trim surrounding whitespaces before copy
      tmux_passthrough = true, -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
    },
  },
}
