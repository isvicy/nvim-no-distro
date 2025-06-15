return {
  cmd = { 'gopls' }, -- Command to start the language server
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl', 'gosum' }, -- File types that this server will handle
  root_markers = { 'go.mod', 'go.work', '.git' }, -- Markers to identify the root of the project
  settings = { -- Settings for the language server
    gopls = {
      usePlaceholders = false,
    },
  },
}
