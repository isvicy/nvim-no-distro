local function create_worktree()
  local fzf = require('fzf-lua')
  local Worktree = require('git-worktree')

  -- Get list of branches and tags
  local branches_and_tags = vim.fn.systemlist('git branch -a && git tag')

  -- Use fzf to select a branch or tag
  fzf.fzf_exec(branches_and_tags, {
    prompt = 'Select branch or tag: ',
    actions = {
      ['default'] = function(selected)
        local branch = selected[1]:gsub('^%s*', ''):gsub('^%*%s*', '')

        -- Determine if it's a remote branch and extract the upstream
        local upstream = nil
        if branch:match('^remotes/') then
          upstream = branch:match('^remotes/([^/]+)')

          branch = branch:gsub('^remotes/[^/]+/', '')
        end

        -- Prompt for the worktree path
        vim.ui.input({ prompt = 'Enter worktree path: ' }, function(path)
          if path and path ~= '' then
            -- Create the worktree
            Worktree.create_worktree(path, branch, upstream)
            print('Worktree created: ' .. path)
          else
            print('Worktree creation cancelled')
          end
        end)
      end,
    },
  })
end

local function switch_worktree()
  local fzf = require('fzf-lua')
  local Worktree = require('git-worktree')

  local worktrees = vim.fn.systemlist('git worktree list')

  fzf.fzf_exec(worktrees, {
    prompt = 'Select worktree to switch to: ',
    actions = {
      ['default'] = function(selected)
        local path = selected[1]:match('^([^%s]+)')
        Worktree.switch_worktree(path)
        print('Switched to worktree: ' .. path)
      end,
    },
  })
end

local function delete_worktree()
  local fzf = require('fzf-lua')
  local Worktree = require('git-worktree')

  local worktrees = vim.fn.systemlist('git worktree list')
  local current_path = vim.fn.getcwd()

  fzf.fzf_exec(worktrees, {
    prompt = 'Select worktree to delete: ',
    actions = {
      ['default'] = function(selected)
        local path = selected[1]:match('^([^%s]+)')
        vim.ui.input(
          { prompt = 'Are you sure you want to delete this worktree? (y/N): ' },
          function(input)
            if input and input:lower() == 'y' then
              local is_current = vim.fn.fnamemodify(path, ':p')
                == vim.fn.fnamemodify(current_path, ':p')

              local actual_git_root
              if is_current then
                -- Get the actual git root directory (where .git is located)
                actual_git_root = vim.fn.systemlist('git rev-parse --git-common-dir')[1]

                -- Change to the actual git root directory before deleting
                vim.cmd('cd ' .. actual_git_root)
              end

              -- considering the user already confirmed deletion, we use force deletion
              Worktree.delete_worktree(path, true)
              print('Deleted worktree: ' .. path)

              if is_current then
                print('Moved to actual git root directory: ' .. actual_git_root)

                -- Close all buffers
                vim.cmd('bufdo bd')

                -- Open a new buffer with the actual git root directory
                vim.cmd('edit ' .. actual_git_root)

                -- Refresh the file explorer (if you're using nvim-tree)
                -- vim.cmd("NvimTreeRefresh")

                -- Or, if you're using another file explorer, you might need to use a different command
                -- For example, with neo-tree:

                -- vim.cmd("Neotree reveal")
              end
            else
              print('Worktree deletion cancelled')
            end
          end
        )
      end,
    },
  })
end

return {
  {
    'ThePrimeagen/git-worktree.nvim',
    dependencies = {
      'ibhagwan/fzf-lua',
    },
    keys = {
      {
        '<leader>gwc',
        create_worktree,
        desc = 'Create Git Worktree',
      },
      {
        '<leader>gws',
        switch_worktree,
        desc = 'Switch Git Worktree',
      },
      {
        '<leader>gwd',
        delete_worktree,
        desc = 'Delete Git Worktree',
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
    keys = { { '<leader>gy', desc = 'copy remote git link of current line or select' } }, -- this is the built-in keymap
    dependencies = { 'ojroques/nvim-osc52', 'nvim-lua/plenary.nvim' },
    config = function()
      require('gitlinker').setup({
        opts = {
          action_callback = function(url)
            -- yank to unnamed register
            vim.api.nvim_command('let @" = \'' .. url .. "'")

            -- copy to the system clipboard using OSC52
            require('osc52').copy(url)
          end,
        },
        callbacks = {
          ['git.enceinte.cc'] = require('gitlinker.hosts').get_gogs_type_url,
          ['dev.msh.team'] = require('gitlinker.hosts').get_gitlab_type_url,
        },
      })
    end,
  },
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
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
