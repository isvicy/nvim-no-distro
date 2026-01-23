return {
  {
    'leoluz/nvim-dap-go',
    ft = { 'go' },
    dependencies = { 'miroshQa/debugmaster.nvim' },
    opts = {
      dap_configurations = {
        {
          type = 'go',
          name = 'Debug Current',
          request = 'launch',
          program = '${fileDirname}',
          cwd = '${fileDirname}',
          env = {
            CGO_ENABLED = '0',
          },
        },
      },
    },
  },
  {
    'miroshQa/debugmaster.nvim',
    dependencies = { 'mfussenegger/nvim-dap', 'jbyuki/one-small-step-for-vimkind' },
    keys = {
      {
        '<leader>d',
        function()
          require('debugmaster').mode.toggle()
        end,
        desc = 'toggle debug mode',
        mode = { 'n', 'v' },
        nowait = true,
      },
    },
    config = function()
      local dm = require('debugmaster')
      dm.plugins.osv_integration.enabled = true -- Needed if you want to debug Lua code of Neovim.
    end,
  },
}
