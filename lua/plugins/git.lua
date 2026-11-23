return {
  {
    'NicolasGB/jj.nvim',
    cmd = {
      'J',
      'Jdiff',
      'Jhdiff',
      'Jvdiff',
      'Jbrowse',
      'Jread',
      'Jedit',
      'Jsplit',
      'Jvsplit',
      'Jtabedit',
    },
    keys = {
      {
        '<leader>jl',
        function()
          require('jj.cmd').log()
        end,
        desc = 'JJ Log',
      },
      {
        '<leader>js',
        function()
          require('jj.cmd').status()
        end,
        desc = 'JJ Status',
      },
      {
        '<leader>jd',
        function()
          require('jj.cmd').describe()
        end,
        desc = 'JJ Describe',
      },
      {
        '<leader>ja',
        function()
          require('jj.annotate').file()
        end,
        desc = 'JJ Annotate (Blame File)',
      },
      {
        '<leader>jA',
        function()
          require('jj.annotate').line()
        end,
        desc = 'JJ Annotate Line',
      },
      {
        '<leader>jb',
        '<cmd>Jbrowse<cr>',
        desc = 'JJ Browse on Remote',
      },
      {
        '<leader>ghb',
        function()
          require('utils.vcs').blame_line()
        end,
        desc = 'Blame Line (git/jj)',
      },
      {
        '<leader>ghB',
        function()
          require('utils.vcs').blame_file()
        end,
        desc = 'Blame Buffer (git/jj)',
      },
    },
    opts = {
      diff = {
        backend = 'diffview',
      },
    },
  },
  {
    'ThePrimeagen/git-worktree.nvim',
    dependencies = {
      'ibhagwan/fzf-lua',
    },
    keys = {
      {
        '<leader>gwc',
        function()
          require('utils.vcs').create_workspace()
        end,
        desc = 'Create Git Worktree / JJ Workspace',
      },
      {
        '<leader>gws',
        function()
          require('utils.vcs').switch_workspace()
        end,
        desc = 'Switch Git Worktree / JJ Workspace',
      },
      {
        '<leader>gwd',
        function()
          require('utils.vcs').delete_workspace()
        end,
        desc = 'Delete Git Worktree / JJ Workspace',
      },
    },
    config = function()
      local Worktree = require('git-worktree')
      Worktree.on_tree_change(function(op, metadata)
        if op == Worktree.Operations.Switch then
          print('Switched from ' .. metadata.prev_path .. ' to ' .. metadata.path)
        end
      end)
    end,
  },
  {
    'ruifm/gitlinker.nvim',
    keys = {
      {
        '<leader>gy',
        function()
          require('utils.vcs').copy_remote_link('n')
        end,
        mode = 'n',
        desc = 'Copy remote git/jj link of current line',
      },
      {
        '<leader>gy',
        '<cmd>lua require("utils.vcs").copy_remote_link("v")<cr>',
        mode = 'v',
        desc = 'Copy remote git/jj link of selection',
      },
    },
    dependencies = { 'ojroques/nvim-osc52', 'nvim-lua/plenary.nvim' },
    config = function()
      local hosts = require('gitlinker.hosts')
      local callbacks = {
        ['git.enceinte.cc'] = hosts.get_gogs_type_url,
      }
      local ok_local, local_callbacks = pcall(require, 'local.gitlinker')
      if ok_local and type(local_callbacks) == 'table' then
        callbacks = vim.tbl_extend('force', callbacks, local_callbacks)
      end

      require('gitlinker').setup({
        opts = {
          action_callback = function(url)
            -- yank to unnamed register
            vim.fn.setreg('"', url)

            -- copy to the system clipboard using OSC52
            require('osc52').copy(url)
          end,
        },
        callbacks = callbacks,
      })

      -- gitlinker.setup() unconditionally binds <leader>gy; rebind to VCS-aware wrapper.
      vim.keymap.set('n', '<leader>gy', function()
        require('utils.vcs').copy_remote_link('n')
      end, { silent = true, desc = 'Copy remote git/jj link of current line' })
      vim.keymap.set(
        'v',
        '<leader>gy',
        '<cmd>lua require("utils.vcs").copy_remote_link("v")<cr>',
        { silent = true, desc = 'Copy remote git/jj link of selection' }
      )
    end,
  },
  {
    'dlyongemallo/diffview.nvim',
    opts = {
      preferred_adapter = 'jj',
    },
    cmd = {
      'DiffviewOpen',
      'DiffviewFileHistory',
      'DiffviewClose',
      'DiffviewToggleFiles',
      'DiffviewFocusFiles',
    },
    keys = {
      {
        '<leader>gm',
        function()
          local view = require('diffview.lib').get_current_view()
          vim.cmd(view and 'DiffviewClose' or 'DiffviewOpen')
        end,
        desc = 'Toggle Diffview (merge/rebase conflicts)',
      },
      {
        '<leader>gf',
        function()
          local view = require('diffview.lib').get_current_view()
          vim.cmd(view and 'DiffviewClose' or 'DiffviewFileHistory %')
        end,
        desc = 'Toggle File History (current file)',
      },
      {
        '<leader>gF',
        function()
          local view = require('diffview.lib').get_current_view()
          vim.cmd(view and 'DiffviewClose' or 'DiffviewFileHistory')
        end,
        desc = 'Toggle File History (repo)',
      },
    },
    init = function()
      vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
          local git_dir = vim.fn.finddir('.git', '.;')
          if git_dir == '' then
            return
          end
          if
            vim.fn.filereadable(git_dir .. '/MERGE_HEAD') == 1
            or vim.fn.isdirectory(git_dir .. '/rebase-merge') == 1
            or vim.fn.isdirectory(git_dir .. '/rebase-apply') == 1
          then
            require('lazy').load({ plugins = { 'diffview.nvim' } })
          end
        end,
      })
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
    opts = {
      signs = {
        add = { text = '▎' },
        change = { text = '▎' },
        delete = { text = '' },
        topdelete = { text = '' },
        changedelete = { text = '▎' },
        untracked = { text = '▎' },
      },
      signs_staged = {
        add = { text = '▎' },
        change = { text = '▎' },
        delete = { text = '' },
        topdelete = { text = '' },

        changedelete = { text = '▎' },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- stylua: ignore start
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })

          else
            gs.nav_hunk("next")

          end
        end, "Next Hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev Hunk")
        map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
        map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
        map("n", "]x", function() vim.fn.search([[^\(<<<<<<<\|=======\|>>>>>>>\)]]) end, "Next Conflict Marker")
        map("n", "[x", function() vim.fn.search([[^\(<<<<<<<\|=======\|>>>>>>>\)]], "b") end, "Prev Conflict Marker")
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end,
    },
  },
}
