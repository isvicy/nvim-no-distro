return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl', 'gosum' },
  root_markers = { 'go.mod', 'go.work', '.jj', '.git' },
  settings = {
    gopls = {
      usePlaceholders = false,
    },
  },
}
