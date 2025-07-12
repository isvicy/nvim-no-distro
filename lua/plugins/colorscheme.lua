return {
  {
    'lmantw/themify.nvim',
    lazy = false,
    priority = 999,
    dependencies = { 'rktjmp/lush.nvim' }, -- acutally, this is needed by sakura.nvim
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
          'anAcc22/sakura.nvim',
        },

        loader = loader,
      })

      vim.api.nvim_set_keymap('n', '<A-t>', ':Themify<CR>', { noremap = true, silent = true })
    end,
  },
}
