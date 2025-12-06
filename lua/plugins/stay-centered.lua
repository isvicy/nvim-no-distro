-- https://github.com/arnamak/stay-centered.nvim
return {
  {
    'arnamak/stay-centered.nvim',
    opts = {
      skip_filetypes = { 'dashboard' },
    },
    config = function(_, opts)
      require('stay-centered').setup(opts)
      -- Define the keymap to toggle the stay-centered plugin
      vim.keymap.set('n', '<leader>US', function()
        require('stay-centered').toggle()
        vim.notify('Toggled stay-centered', vim.log.levels.INFO)
      end, { desc = 'Toggle stay-centered.nvim' })
    end,
  },
}
