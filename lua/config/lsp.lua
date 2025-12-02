vim.lsp.enable({
  'gopls',
  'lua_ls',
  'ruff',
  'nil_ls',
  'golangci_lint_ls',
  'docker_language_server',
  'bashls',
  'terraformls',
  'rust_analyzer',
})

vim.lsp.enable('basedpyright')
vim.lsp.enable('ruff')
vim.lsp.config['basedpyright'] = {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', '.git', 'pyrightconfig.json' },
  settings = {
    basedpyright = {
      disableOrganizeImports = true,
      analysis = {
        typeCheckingMode = 'standard',
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
  on_attach = function(client, _)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}

vim.lsp.config['ruff'] = {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.git' },
  init_options = {
    settings = {
      -- Ruff 专有设置
      logLevel = 'debug',
    },
  },
  on_attach = function(client, _)
    client.server_capabilities.hoverProvider = false
  end,
}

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
