return {
  'm4xshen/hardtime.nvim',
  enabled = true,
  dependencies = { 'MunifTanjim/nui.nvim' },
  event = 'BufEnter',
  opts = function(_, opts)
    -- Make sure the default table exists
    opts.restricted_keys = opts.restricted_keys or {}
    -- Do NOT restrict gj / gk
    opts.restricted_keys['gj'] = false
    opts.restricted_keys['gk'] = false
    opts.max_count = 12
  end,
}
