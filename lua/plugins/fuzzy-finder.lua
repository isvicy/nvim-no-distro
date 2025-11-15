return {
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    opts = function(_, _)
      local fzf = require('fzf-lua')
      local config = fzf.config
      local actions = fzf.actions

      -- Quickfix
      config.defaults.keymap.fzf['ctrl-q'] = 'select-all+accept'
      config.defaults.keymap.fzf['ctrl-u'] = 'half-page-up'
      config.defaults.keymap.fzf['ctrl-d'] = 'half-page-down'
      config.defaults.keymap.fzf['ctrl-x'] = 'jump'
      config.defaults.keymap.fzf['ctrl-f'] = 'preview-page-down'
      config.defaults.keymap.fzf['ctrl-b'] = 'preview-page-up'
      config.defaults.keymap.builtin['<c-f>'] = 'preview-page-down'
      config.defaults.keymap.builtin['<c-b>'] = 'preview-page-up'

      return {
        'default-title',
        fzf_colors = true,
        fzf_opts = {

          ['--no-scrollbar'] = true,
        },
        defaults = {
          -- formatter = "path.filename_first",
          formatter = 'path.dirname_first',
        },
        winopts = {
          width = 0.8,
          height = 0.8,
          row = 0.5,
          col = 0.5,
          preview = {
            layout = 'vertical',
            scrollchars = { '┃', '' },
            vertical = 'up:50%',
          },
        },

        files = {
          cwd_prompt = false,
          actions = {
            ['alt-i'] = { actions.toggle_ignore },
            ['alt-h'] = { actions.toggle_hidden },
          },
        },
        grep = {
          actions = {
            ['alt-i'] = { actions.toggle_ignore },

            ['alt-h'] = { actions.toggle_hidden },
          },
        },

        lsp = {
          symbols = {
            symbol_hl = function(s)
              return 'TroubleIcon' .. s
            end,
            symbol_fmt = function(s)
              return s:lower() .. '\t'
            end,
            child_prefix = false,
          },
          code_actions = {
            previewer = vim.fn.executable('delta') == 1 and 'codeaction_native' or nil,
          },
        },
      }
    end,
    config = function(_, opts)
      require('fzf-lua').setup(opts)
      require('fzf-lua').register_ui_select()
    end,
    keys = {
      { '<c-j>', '<c-j>', ft = 'fzf', mode = 't', nowait = true },
      { '<c-k>', '<c-k>', ft = 'fzf', mode = 't', nowait = true },

      {
        '<leader>,',
        '<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>',
        desc = 'Switch Buffer',
      },

      { '<leader>/', '<cmd>Fzflua live_grep<cr>', desc = 'Grep (Root Dir)' },
      { '<leader>:', '<cmd>FzfLua command_history<cr>', desc = 'Command History' },
      { '<leader><space>', '<cmd>FzfLua files<cr>', desc = 'Find Files (Root Dir)' },

      -- find
      {
        '<leader>fb',
        '<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>',
        desc = 'Buffers',
      },
      -- { '<leader>ff', '<cmd>FzfLua files<cr>', desc = 'Find Files (Root Dir)' },
      {
        '<leader>fc',
        function()
          require('fzf-lua').files({ cwd = vim.fn.stdpath('config') })
        end,
        desc = 'Find Config File',
      },
      { '<leader>fg', '<cmd>FzfLua git_files<cr>', desc = 'Find Files (git-files)' },
      { '<leader>fr', '<cmd>FzfLua oldfiles<cr>', desc = 'Recent' },
      {
        '<leader>fR',
        function()
          require('fzf-lua').oldfiles({ cwd = vim.uv.cwd() })
        end,
        desc = 'Recent (cwd)',
      },

      -- git
      { '<leader>gc', '<cmd>FzfLua git_commits<CR>', desc = 'Commits' },
      { '<leader>gs', '<cmd>FzfLua git_status<CR>', desc = 'Status' },

      -- search
      { '<leader>s"', '<cmd>FzfLua registers<cr>', desc = 'Registers' },
      { '<leader>sa', '<cmd>FzfLua autocmds<cr>', desc = 'Auto Commands' },
      { '<leader>sb', '<cmd>FzfLua grep_curbuf<cr>', desc = 'Buffer' },
      { '<leader>sc', '<cmd>FzfLua command_history<cr>', desc = 'Command History' },
      { '<leader>sC', '<cmd>FzfLua commands<cr>', desc = 'Commands' },
      { '<leader>sd', '<cmd>FzfLua diagnostics_document<cr>', desc = 'Document Diagnostics' },
      { '<leader>sD', '<cmd>FzfLua diagnostics_workspace<cr>', desc = 'Workspace Diagnostics' },
      { '<leader>sg', '<cmd>Fzflua live_grep<cr>', desc = 'Grep (Root Dir)' },
      { '<leader>sh', '<cmd>FzfLua help_tags<cr>', desc = 'Help Pages' },
      { '<leader>sH', '<cmd>FzfLua highlights<cr>', desc = 'Search Highlight Groups' },
      { '<leader>sj', '<cmd>FzfLua jumps<cr>', desc = 'Jumplist' },
      { '<leader>sk', '<cmd>FzfLua keymaps<cr>', desc = 'Key Maps' },
      { '<leader>sl', '<cmd>FzfLua loclist<cr>', desc = 'Location List' },
      { '<leader>sM', '<cmd>FzfLua man_pages<cr>', desc = 'Man Pages' },
      { '<leader>sm', '<cmd>FzfLua marks<cr>', desc = 'Jump to Mark' },
      { '<leader>sR', '<cmd>FzfLua resume<cr>', desc = 'Resume' },
      { '<leader>sq', '<cmd>FzfLua quickfix<cr>', desc = 'Quickfix List' },
      { '<leader>sw', '<cmd>FzfLua grep_cword<cr>', desc = 'Word (Root Dir)' },
      { '<leader>sw', '<cmd>FzfLua grep_visual<cr>', mode = 'v', desc = 'Selection (Root Dir)' },
      { '<leader>uC', '<cmd>FzfLua colorschemes<cr>', desc = 'Colorscheme with Preview' },
      {
        '<leader>ss',
        function()
          require('fzf-lua').lsp_document_symbols({})
        end,
        desc = 'Goto Symbol',
      },
      {
        '<leader>sS',
        function()
          require('fzf-lua').lsp_live_workspace_symbols({})
        end,
        desc = 'Goto Symbol (Workspace)',
      },
    },
  },
  {
    'dmtrKovalenko/fff.nvim',
    build = function()
      local is_nixos = vim.fn.executable('nixos-version') == 1
      if is_nixos then
        vim.fn.system('nix run .#release')
      else
        require('fff.download').download_or_build_binary()
      end
    end,
    opts = {},
    lazy = false,
    keys = {
      {
        '<leader>ff',
        function()
          require('fff').find_files()
        end,
        desc = 'FFFind files',
      },
    },
  },
  {
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    keys = {
      {
        '<leader>fw',
        function()
          local grug = require('grug-far')

          grug.open({
            transient = true,
            prefills = {
              search = vim.fn.expand('<cword>'),
            },
          })
        end,
        mode = { 'n', 'v' },
        desc = 'search current word',
      },
      {
        '<leader>sr',
        function()
          local grug = require('grug-far')
          grug.open({
            transient = true,
          })
        end,
        mode = { 'n', 'v' },
        desc = 'Search and Replace',
      },
    },
    opts = {
      normalModeSearch = true,
      headerMaxWidth = 80,
      engines = {
        ripgrep = { defaults = { flags = '--smart-case --hidden' } },
        astgrep = { defaults = { flags = '--strictness relaxed' } },
      },
    },
  },
}
