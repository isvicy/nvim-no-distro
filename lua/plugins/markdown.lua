return {
  -- Markdown preview in browser (existing)
  {
    'toppair/peek.nvim',
    ft = 'markdown',
    build = 'deno task --quiet build:fast',
    config = function()
      require('peek').setup()
      vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
      vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})
    end,
  },

  -- Render markdown with icons and highlights
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
      bullet = {
        enabled = true,
      },
      checkbox = {
        enabled = true,
        position = 'inline',
        unchecked = {
          icon = '   󰄱 ',
          highlight = 'RenderMarkdownUnchecked',
        },
        checked = {
          icon = '   󰱒 ',
          highlight = 'RenderMarkdownChecked',
        },
      },
      html = {
        enabled = true,
        comment = {
          conceal = false,
        },
      },
      link = {
        image = '󰥶 ',
        custom = {
          youtu = { pattern = 'youtu%.be', icon = '󰗃 ' },
        },
      },
      heading = {
        sign = false,
        icons = { '󰎤 ', '󰎧 ', '󰎪 ', '󰎭 ', '󰎱 ', '󰎳 ' },
        backgrounds = {
          'RenderMarkdownH1Bg',
          'RenderMarkdownH2Bg',
          'RenderMarkdownH3Bg',
          'RenderMarkdownH4Bg',
          'RenderMarkdownH5Bg',
          'RenderMarkdownH6Bg',
        },
        foregrounds = {
          'RenderMarkdownH1',
          'RenderMarkdownH2',
          'RenderMarkdownH3',
          'RenderMarkdownH4',
          'RenderMarkdownH5',
          'RenderMarkdownH6',
        },
      },
      code = {
        style = 'full',
        highlight = 'RenderMarkdownCode',
      },
    },
  },

  -- Auto bullet points for lists
  {
    'bullets-vim/bullets.vim',
    ft = { 'markdown', 'text', 'gitcommit' },
    config = function()
      vim.g.bullets_delete_last_bullet_if_empty = 2
    end,
  },

  -- Paste images from clipboard
  {
    'HakonHarnes/img-clip.nvim',
    ft = 'markdown',
    opts = {
      default = {
        use_absolute_path = false,
        relative_to_current_file = true,
        dir_path = function()
          return vim.fn.expand('%:t:r') .. '-img'
        end,
        prompt_for_file_name = false,
        file_name = '%y%m%d-%H%M%S',
        extension = 'avif',
        process_cmd = 'convert - -quality 75 avif:-',
      },
      filetypes = {
        markdown = {
          url_encode_path = true,
          template = '![Image](./$FILE_PATH)',
        },
      },
    },
    keys = {
      { '<leader>pi', '<cmd>PasteImage<cr>', ft = 'markdown', desc = 'Paste image from clipboard' },
    },
  },
  {
    'hotoo/pangu.vim',
    ft = 'markdown',
    cmd = 'Pangu',
  },
}
