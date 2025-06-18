return {
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
      routes = {
        {
          filter = {
            event = 'msg_show',
            any = {
              { find = '%d+L, %d+B' },
              { find = '; after #%d+' },

              { find = '; before #%d+' },
            },
          },
          view = 'mini',
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>sn", "", desc = "+noice"},

      { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
      { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
      { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },

      { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
      { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
      { "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice Picker (Telescope/FzfLua)" },
      { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll Forward", mode = {"i", "n", "s"} },
      { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll Backward", mode = {"i", "n", "s"}},
    },
    config = function(_, opts)
      -- HACK: noice shows messages from before it was enabled,
      -- but this is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.o.filetype == 'lazy' then
        vim.cmd([[messages clear]])
      end
      require('noice').setup(opts)
    end,
  },

  {
    'nvimdev/dashboard-nvim',
    event = 'UIEnter',
    opts = function()
      local logo = [[
⠘⢿⣦⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⣿⡎⠉⠉⠛⠻⣶⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⣿⠃⠀⢀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⢻⣁⠀⠀⠀⠀⠈⢻⡆⠀⠠⣴⣤⣀⣠⣤⠀⢠⣾⡇⠀⢶⣴⠶⢿⠾⢷⣄⢿⡆⠀⠀⢹⡏⠀⠀⠀⠀⠀⢴⣶⡆⠀⠀⠰⣾⠟⠁⠀⠀⠀⠀⠀⣦⣄⣀⣿⣃⣀⣀⠀⠀⠀⠀⠀⠀       
⠀⢸⡇⠀⢀⣀⡀⠀⢸⣿⡄⠀⣵⠀⠀⠈⠉⠀⢸⠏⢷⠀⠀⠀⠀⢸⡄⠀⠀⢸⡇⠀⠀⢸⡇⠀⠀⠀⠀⠀⢸⡿⠻⣆⠀⠀⣿⠀⠀⣠⡶⢶⣄⠀⠉⠉⠉⣿⠏⠉⠉⣶⣦⣤⡶⠶⣂       
⠀⠀⣇⠀⠘⠛⠁⠀⠈⣿⣧⠀⣿⣠⣤⡤⣄⠀⣸⠀⣸⣆⣄⠀⠀⢸⡇⠀⠐⠚⡟⠋⠉⣽⠋⠀⠀⠀⠀⠀⢸⡇⠀⠘⣧⡀⢸⠀⣴⢋⣠⣄⢹⣦⠀⠀⣠⣿⠀⠀⠀⣿⡇⠀⠀⠀⠀       
⠀⠀⣿⠀⠀⠀⠀⠀⢀⣿⠇⠀⣿⠀⠉⠉⠋⠀⣿⠿⠿⢿⡏⠀⠀⢸⡇⠀⠀⠀⡇⠀⠀⣿⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠹⣿⣸⡆⣿⠈⠙⠋⠀⣿⠀⠀⢹⡇⠀⠀⠀⢹⣷⣶⣤⣴⠀       
⠀⠀⣿⠀⠀⠀⠀⣀⣼⠃⠀⢰⣧⣤⣤⣤⡄⢀⣿⠀⠀⢸⣧⠀⠀⣘⣿⠀⠀⠀⣿⠀⠀⢿⡀⠀⠀⠀⠀⠀⠸⣧⠀⠀⠀⠙⣿⡇⠹⢦⣤⣤⣾⠋⠀⠠⠼⠷⠀⠀⠀⢸⣿⠀⠀⠀⠀       
⠀⢀⣿⣀⣤⣶⠿⠋⠀⠀⣀⣤⣶⣿⣿⣿⣷⣶⣶⣶⣤⡀⠀⠀⠀⠈⠙⠃⠀⠚⠛⠀⠀⠘⠉⠀⠀⠀⠀⠀⠚⠉⠀⠀⠀⣠⣬⣿⣶⣶⣾⣿⣿⣿⡿⠿⣶⣦⣤⡀⠀⣼⣿⣤⣤⣤⣄       
⠀⢸⣿⠛⠁⠀⠀⣠⣶⠟⠛⢻⡟⠀⠈⢹⣿⠉⢹⣿⡿⣿⣦⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣿⣿⡿⢿⣿⡟⠁⢻⣿⠁⠀⠀⠀⣿⠉⠙⠳⣤⡀⠀⠀⠀⠀       
⠀⠀⠀⠀⣠⠶⠋⠁⠀⠀⠀⠈⡇⠀⠀⠘⣿⠀⠀⢸⡇⠈⠻⣿⣿⣿⣷⣦⣤⣤⣄⡀⠀⠀⢀⡀⡀⡀⠀⣴⣿⠿⣿⣿⠀⡿⠀⢸⡏⠀⠀⢸⠃⠀⠀⠀⠀⠃⠀⠀⠀⠈⠉⢳⣄⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠀⠀⠈⢿⠀⠀⠘⡟⠀⠀⠹⣿⢿⣿⣤⣀⣈⣿⣿⣿⣥⡾⠛⠉⠀⢸⡏⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠀⠀⠀⠇⠀⠀⠀⠻⠀⠀⣼⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠘⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣺⣿⢻⣿⣿⣿⠟⢻⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⠇⣿⣿⣿⣿⣇⠘⢿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡏⣸⣿⣿⠿⣿⣿⠀⢻⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢙⡇⢿⣿⡇⠀⢻⣿⡄⢸⡗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣟⣄⣿⡅⠀⠠⣿⣧⢾⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⣿⡇⠀⣼⣿⠛⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣇⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⢠⡿⢿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⢸⣿⡄⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣇⡼⠏⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
        ]]

      local opts = {
        theme = 'doom',
        hide = { statusline = true },
        config = {
          header = vim.split(logo, '\n'),
          vertical_center = true,
          center = {
            {
              action = 'FzfLua files',
              desc = '',
              icon = '',
              key = 'f',
            },
          },
          footer = function()
            local stats = require('lazy').stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return {
              ' Neovim loaded '
                .. stats.loaded
                .. '/'
                .. stats.count
                .. ' plugins in '
                .. ms
                .. 'ms',
            }
          end,
        },
      }

      -- open dashboard after closing lazy
      if vim.o.filetype == 'lazy' then
        vim.api.nvim_create_autocmd('WinClosed', {
          pattern = tostring(vim.api.nvim_get_current_win()),
          once = true,
          callback = function()
            vim.schedule(function()
              vim.api.nvim_exec_autocmds('UIEnter', { group = 'dashboard' })
            end)
          end,
        })
      end

      return opts
    end,
  },
}
