return {
  {
    'lmantw/themify.nvim',
    lazy = false,
    priority = 999,
    dependencies = 'rktjmp/lush.nvim', -- Required for lush themes, like zenbones
    config = function()
      local function loader()
        local Themify = require('themify.api')

        -- use light theme when using e-ink display
        if vim.env.INK then
          local id = 'yorickpeterse/nvim-grey'
          local colorscheme_data = Themify.Manager.get(id)
          Themify.set_current(id, colorscheme_data.themes[math.random(#colorscheme_data.themes)])

          return
        end

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

        loader = loader,
        async = true,
        activity = true,
      })

      vim.api.nvim_set_keymap('n', '<A-t>', ':Themify<CR>', { noremap = true, silent = true })
    end,
  },
}
