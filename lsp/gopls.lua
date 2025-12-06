return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl', 'gosum' },
  root_markers = { 'go.mod', 'go.work', '.git' },
  settings = {
    gopls = {
      usePlaceholders = false,
    },
  },
}
