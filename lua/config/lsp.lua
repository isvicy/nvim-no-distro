vim.lsp.enable('gopls')
vim.lsp.enable('golangci_lint_ls')
vim.lsp.enable('lua_ls')
vim.lsp.enable('nil_ls')
vim.lsp.enable('docker_language_server')
vim.lsp.enable('bashls')
vim.lsp.enable('terraformls')
vim.lsp.enable('rust_analyzer')
vim.lsp.enable('basedpyright')
vim.lsp.enable('ruff')

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
