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

      local dap = require('dap')
      dap.adapters['pwa-node'] = {
        type = 'server',
        host = '127.0.0.1',
        port = '${port}',
        executable = {
          command = 'js-debug',
          args = { '${port}', '127.0.0.1' },
        },
      }
      dap.adapters.codelldb = {
        type = 'server',
        port = '${port}',
        executable = {
          command = 'codelldb',
          args = { '--port', '${port}' },
        },
      }

      local js_configurations = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch current file',
          program = '${file}',
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          console = 'integratedTerminal',
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch current file with tsx',
          program = '${file}',
          runtimeArgs = { '--import', 'tsx' },
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          console = 'integratedTerminal',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach to process',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
      }
      for _, filetype in ipairs({ 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' }) do
        dap.configurations[filetype] = js_configurations
      end

      dap.configurations.rust = {
        {
          type = 'codelldb',
          request = 'launch',
          name = 'Launch Rust executable',
          program = function()
            local program = vim.fn.input({
              prompt = 'Executable: ',
              default = vim.fn.getcwd() .. '/target/debug/',
              completion = 'file',
            })
            if program == '' then
              return dap.ABORT
            end
            return program
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          sourceLanguages = { 'rust' },
        },
      }
    end,
  },
}
