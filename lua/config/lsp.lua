vim.lsp.enable({
  'gopls',
  'lua_ls',
  'ruff',
  'nil_ls',
})

vim.diagnostic.config({
  virtual_lines = false, -- Disable virtual lines completely
  underline = false,
  virtual_text = false,
  float = {
    show_header = false,
    format = function(diagnostic)
      if diagnostic.code then
        return string.format('%s(%s) - %s', diagnostic.source, diagnostic.code, diagnostic.message)
      end
      return string.format('%s - %s', diagnostic.source, diagnostic.message)
    end,
  },
})
