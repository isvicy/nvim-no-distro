-- mini.files - File explorer
-- Based on neobean config: https://github.com/echasnovski/mini.files

local mini_files_git = require('config.modules.mini-files-git')

return {
  'echasnovski/mini.files',
  version = false,
  opts = function(_, opts)
    -- Custom mappings
    opts.mappings = vim.tbl_deep_extend('force', opts.mappings or {}, {
      close = '<esc>',
      -- Use this if you want to open several files
      go_in = 'l',
      -- This opens the file, but quits out of mini.files
      go_in_plus = '<CR>',
      -- go_out_plus: when you go out, it shows you only 1 item to the right
      -- go_out: shows you all the items to the right
      go_out = 'H',
      go_out_plus = 'h',
      reset = '<BS>',
      reveal_cwd = '.',
      show_help = 'g?',
      synchronize = 's',
      trim_left = '<',
      trim_right = '>',
    })

    opts.windows = vim.tbl_deep_extend('force', opts.windows or {}, {
      preview = true,
      width_focus = 30,
      width_preview = 80,
    })

    opts.options = vim.tbl_deep_extend('force', opts.options or {}, {
      -- Use as default explorer (instead of netrw)
      use_as_default_explorer = true,
      -- Files are moved to trash instead of permanent delete
      permanent_delete = false,
    })

    return opts
  end,

  keys = {
    {
      -- Open the directory of the file currently being edited
      '<leader>e',
      function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        local dir_name = vim.fn.fnamemodify(buf_name, ':p:h')
        if vim.fn.filereadable(buf_name) == 1 then
          require('mini.files').open(buf_name, true)
        elseif vim.fn.isdirectory(dir_name) == 1 then
          require('mini.files').open(dir_name, true)
        else
          require('mini.files').open(vim.uv.cwd(), true)
        end
      end,
      desc = 'Open mini.files (current file dir)',
    },
    {
      -- Open the current working directory
      '<leader>E',
      function()
        require('mini.files').open(vim.uv.cwd(), true)
      end,
      desc = 'Open mini.files (cwd)',
    },
  },

  config = function(_, opts)
    require('mini.files').setup(opts)

    -- Load Git integration
    mini_files_git.setup()

    -- Custom keymaps in mini.files buffer
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        local buf_id = args.data.buf_id
        local mini_files = require('mini.files')

        -- Copy path to clipboard
        vim.keymap.set('n', '<M-c>', function()
          local curr_entry = mini_files.get_fs_entry()
          if curr_entry then
            local home_dir = vim.fn.expand('~')
            local relative_path = curr_entry.path:gsub('^' .. home_dir, '~')
            vim.fn.setreg('+', relative_path)
            vim.notify('Path copied: ' .. relative_path, vim.log.levels.INFO)
          else
            vim.notify('No file or directory selected', vim.log.levels.WARN)
          end
        end, { buffer = buf_id, noremap = true, silent = true, desc = 'Copy path to clipboard' })
      end,
    })
  end,
}
