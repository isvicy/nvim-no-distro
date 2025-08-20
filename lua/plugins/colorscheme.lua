return {
  {
    'lmantw/themify.nvim',
    lazy = false,
    priority = 999,
    dependencies = 'rktjmp/lush.nvim', -- Required for lush themes, like zenbones
    config = function()
      local function loader()
        local Themify = require('themify.api')

        math.randomseed(os.time())

        local colorscheme_id =
          Themify.Manager.colorschemes[math.random(#Themify.Manager.colorschemes)]
        local colorscheme_data = Themify.Manager.get(colorscheme_id)

        Themify.set_current(
          colorscheme_id,
          colorscheme_data.themes[math.random(#colorscheme_data.themes)]
        )
      end

      require('themify').setup({
        'datsfilipe/vesper.nvim',
        'sam4llis/nvim-tundra',
        {
          'metalelf0/black-metal-theme-neovim',
          after = function()
            require('black-metal').setup({
              theme = 'bathory',
              variant = 'dark',
            })
            require('black-metal').load()
          end,
          whitelist = { 'bathory' },
        },
        {
          before = function()
            vim.cmd [[set background=light]]
          end,
          'zenbones-theme/zenbones.nvim',
          whitelist = { 'zenbones' },
        },
        {
          'mitch1000/backpack',
          after = function()
            require('backpack').setup({
              contrast = 'extreme',
            })
          end,
        },

        loader = loader,
        async = true,
        activity = true,
      })

      vim.api.nvim_set_keymap('n', '<A-t>', ':Themify<CR>', { noremap = true, silent = true })
    end,
  },
}
