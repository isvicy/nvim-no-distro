return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>fm',
        function()
          require('conform').format({ async = true, lsp_format = 'fallback' })
        end,
        mode = 'n',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      formatters = {
        shfmt = {
          args = { '-i', '2', '-ci' },
        },
        deno_fmt = {
          args = { 'fmt', '-', '--ext=md', '--prose-wrap=always', '--line-width=80' },
        },
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        go = { 'gofumpt', 'goimports' },
        nix = { 'alejandra' },
        json = { 'jq' },
        yaml = { 'yq' },
        python = { 'black', 'isort' },
        html = { 'htmlbeautifier' },
        markdown = { 'deno_fmt' },
        sh = { 'shfmt', 'shellcheck' },
        terraform = { 'terraform_fmt' },
        toml = { 'tombi' },
        proto = { 'buf' },
      },
    },
  },
}
