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
    config = function()
      local dm = require('debugmaster')
      vim.keymap.set({ 'n', 'v' }, '<leader>d', dm.mode.toggle, { nowait = true })

      dm.plugins.osv_integration.enabled = true -- needed if you want to debug neovim lua code
    end,
  },
}
