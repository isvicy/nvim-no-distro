return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = '<M-p>',
            accept_line = '<M-o>',
            accept_word = '<M-w>',
          },
        },
        filetypes = {
          yaml = true,
          markdown = true,
          gitcommit = true,
          gitrebase = true,
          ['dap-repl'] = false,
          ['grug-far'] = false,
          ['grug-far-history'] = false,
          ['grug-far-help'] = false,
        },
        copilot_model = 'gpt-4o-copilot',
      })
      -- set highlight group for copilot
      local comment_hl = vim.api.nvim_get_hl(0, { name = 'Comment' })
      vim.api.nvim_set_hl(0, 'CopilotSuggestion', { italic = true, fg = comment_hl.fg })
    end,
  },
}
