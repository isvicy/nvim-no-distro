return {
  {
    'leoluz/nvim-dap-go',
    ft = { 'go' },

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
    'mfussenegger/nvim-dap',
    dependencies = {
      -- Creates a beautiful debugger UI
      'rcarriga/nvim-dap-ui',

      -- Required dependency for nvim-dap-ui
      'nvim-neotest/nvim-nio',
      -- Shows variable values inline as virtual text
      'theHamsta/nvim-dap-virtual-text',
    },
    keys = {
      {
        '<leader>Dc',
        function()
          require('dap').continue()
        end,
        desc = 'Debug: Start/Continue',
      },
      {
        '<leader>Dsi',
        function()
          require('dap').step_into()
        end,
        desc = 'Debug: Step Into',
      },
      {
        '<leader>DsO',
        function()
          require('dap').step_over()
        end,
        desc = 'Debug: Step Over',
      },
      {
        '<leader>Dso',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: Step Out',
      },

      {
        '<leader>Db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Debug: Toggle Breakpoint',
      },
      {
        '<leader>DB',
        function()
          require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
        end,

        desc = 'Debug: Set Conditional Breakpoint',
      },
      {
        '<leader>Dt',
        function()
          require('dapui').toggle()
        end,
        desc = 'Debug: Toggle UI',
      },
      {

        '<leader>Dl',
        function()
          require('dap').run_last()
        end,
        desc = 'Debug: Run Last Configuration',
      },
    },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')

      -- optional
      -- require('mason-nvim-dap').setup {
      --     automatic_installation = true,
      --     handlers = {},
      --     ensure_installed = {
      --         'delve',
      --     },
      -- }

      -- Dap UI setup
      dapui.setup({
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
          icons = {

            pause = '⏸',
            play = '▶',
            step_into = '⏎',
            step_over = '⏭',
            step_out = '⏮',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏹',
            disconnect = '⏏',
          },
        },
      })

      -- Automatically open/close DAP UI
      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      -- Setup virtual text to show variable values inline
      require('nvim-dap-virtual-text').setup()
    end,
  },
}
