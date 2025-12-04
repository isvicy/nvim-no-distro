return {
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
