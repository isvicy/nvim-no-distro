# Neovim Configuration

A modern, modular Neovim configuration focused on Go development with excellent LSP support, fuzzy finding, and Git integration.

## Features

- 🚀 **Modern Neovim 0.11+** - Uses latest built-in LSP features
- 📦 **Modular Plugin System** - Organized by functionality with lazy loading
- 🎯 **Go Development** - Specialized tools for Go (build, debug, linting)
- 🔍 **Fuzzy Finding** - Fast file/text search with fzf-lua
- 🎨 **Syntax Highlighting** - Treesitter-based with custom fold text
- 📝 **Smart Completion** - Blink.cmp with LSP and snippets
- 🌳 **Git Integration** - Gitsigns, worktrees, diffview, gitlinker
- 🎭 **Database Tools** - PostgreSQL connection management
- ⚡ **Performance Optimized** - Strategic lazy loading and version pinning

## Requirements

- Neovim >= 0.11
- Git >= 2.19
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for live grep)
- [fd](https://github.com/sharkdp/fd) (optional, for faster file finding)
- [fzf](https://github.com/junegunn/fzf) (for fuzzy finding)
- A Nerd Font (for icons)
- Language servers:
  - `gopls` (Go)
  - `lua-language-server` (Lua)
  - `bash-language-server` (Bash)
  - `terraform-ls` (Terraform)
  - Other LSPs as needed

## Installation

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.backup

# Clone this repository
git clone <your-repo-url> ~/.config/nvim

# Start Neovim (plugins will auto-install)
nvim
```

## Structure

```
.
├── init.lua                 # Entry point
├── lua/
│   ├── config/             # Core configuration
│   │   ├── opt.lua         # Neovim options
│   │   ├── keymap.lua      # Base keymaps
│   │   ├── autocmd.lua     # Autocommands and custom commands
│   │   ├── lsp.lua         # LSP configuration
│   │   └── lazy.lua        # Plugin manager setup
│   ├── plugins/            # Plugin specifications
│   │   ├── editor.lua      # Which-key
│   │   ├── fuzzy-finder.lua # FzfLua, GrugFar
│   │   ├── navigation.lua  # Flash.nvim
│   │   ├── terminal.lua    # NvTerm
│   │   ├── treesitter.lua  # Syntax highlighting
│   │   ├── editing.lua     # Mini.nvim, autopairs, etc.
│   │   ├── git.lua         # Git plugins
│   │   ├── blink.lua       # Completion
│   │   ├── lsp/            # LSP plugins
│   │   ├── dap.lua         # Debugging
│   │   ├── ui.lua          # UI enhancements
│   │   └── ...
│   └── utils/              # Utility modules
│       ├── init.lua        # Core utilities
│       ├── go.lua          # Go development tools
│       ├── database.lua    # Database utilities
│       ├── git.lua         # Git utilities
│       └── fold.lua        # Custom fold text
├── lsp/                    # LSP server configurations
│   ├── gopls.lua          # Go language server config
│   └── lua_ls.lua         # Lua language server config
└── stylua.toml            # Lua code formatting config
```

## Key Mappings

> **Leader Key**: `Space`

### General

| Key | Mode | Description |
|-----|------|-------------|
| `<C-h/j/k/l>` | n | Navigate windows |
| `<leader>p/P` | n | Paste from yank register |
| `Y` | n | Yank to end of line |
| `n/N` | n | Search with auto-center |
| `*` | n | Highlight word without jumping |
| `<Arrow keys>` | n | Resize windows |

### File/Find (`<leader>f`)

| Key | Description |
|-----|-------------|
| `<leader><space>` | Find files |
| `<leader>,` | Switch buffer |
| `<leader>/` | Live grep |
| `<leader>:` | Command history |
| `<leader>fb` | Buffers |
| `<leader>fc` | Find config files |
| `<leader>fg` | Git files |
| `<leader>fr` | Recent files |
| `<leader>ff` | FFF file picker |
| `<leader>fw` | Search current word |

### Search (`<leader>s`)

| Key | Description |
|-----|-------------|
| `<leader>s"` | Registers |
| `<leader>sb` | Buffer search |
| `<leader>sd` | Document diagnostics |
| `<leader>sD` | Workspace diagnostics |
| `<leader>sg` | Grep |
| `<leader>sh` | Help tags |
| `<leader>sk` | Keymaps |
| `<leader>sr` | Search and replace (GrugFar) |
| `<leader>ss` | Document symbols |
| `<leader>sS` | Workspace symbols |

### Code (`<leader>c`)

| Key | Description |
|-----|-------------|
| `gd` | Go to definition (FzfLua) |
| `gr` | Go to references (FzfLua) |
| `gI` | Go to implementation (FzfLua) |
| `gy` | Go to type definition (FzfLua) |
| `K` | Hover documentation |
| `gl` | Open diagnostic float |
| `<leader>cr` | Rename symbol |
| `<leader>ca` | Code actions |
| `<leader>cf` | Format buffer |
| `<leader>ccd` | Copy diagnostic |
| `<leader>cgb` | Go build (async with quickfix) |
| `<leader>cds` | Setup Go debug config |

### Git (`<leader>g`)

| Key | Description |
|-----|-------------|
| `<leader>gc` | Git commits |
| `<leader>gs` | Git status |
| `<leader>gy` | Copy git link |
| `<leader>gld` | View line commit diff |
| `<leader>gwc` | Create git worktree |
| `<leader>gws` | Switch git worktree |
| `<leader>gwd` | Delete git worktree |

#### Git Hunks (`<leader>gh`)

| Key | Description |
|-----|-------------|
| `]h/[h` | Next/prev hunk |
| `]H/[H` | Last/first hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghS` | Stage buffer |
| `<leader>ghR` | Reset buffer |
| `<leader>ghp` | Preview hunk inline |
| `<leader>ghb` | Blame line |
| `<leader>ghd` | Diff this |

### Navigation

| Key | Description |
|-----|-------------|
| `s` | Flash jump |
| `S` | Flash treesitter |
| `r` | Remote flash (operator mode) |
| `]m/[m` | Next/prev function |
| `]]]/[[[` | Next/prev class |
| `]d/[d` | Next/prev diagnostic |

### Terminal

| Key | Mode | Description |
|-----|------|-------------|
| `<A-h>` | n,t,i | Toggle horizontal terminal |
| `<A-v>` | n,t,i | Toggle vertical terminal |
| `<A-f>` | n,t,i | Toggle floating terminal |
| `<Esc>` | t | Exit terminal mode |

### Debug (`<leader>d`)

| Key | Description |
|-----|-------------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue |
| `<leader>dC` | Run to cursor |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | REPL toggle |
| `<leader>dl` | Run last |
| `<leader>dt` | Terminate |

## Custom Commands

- `:GoBuild` - Async Go build with quickfix integration
- `:GoDebugSetup` - Interactive Go debug configuration
- `:CopyDiagnostic` - Copy LSP diagnostic to clipboard
- `:DiffViewLineCommit` - View git blame commit diff
- `:DBUIPrompt` - Interactive database connection setup
- `:PrintFullPath` - Print and copy file's full path
- `:PeekOpen/PeekClose` - Markdown preview

## Language Server Configuration

LSP servers are configured in the `lsp/` directory and automatically loaded by Neovim 0.11's built-in LSP system.

Current servers:
- **gopls** - Go language server
- **lua_ls** - Lua language server
- **bashls** - Bash language server
- **terraformls** - Terraform language server
- **ruff** - Python linter
- **golangci_lint_ls** - Go linter

To enable a new LSP:
1. Create `lsp/<server-name>.lua` with server config
2. Add server name to `lua/config/lsp.lua` in `vim.lsp.enable()` call

Example LSP config (`lsp/example.lua`):
```lua
return {
  cmd = { 'example-lsp', '--stdio' },
  filetypes = { 'example' },
  root_markers = { '.git', 'example.toml' },
  settings = {
    example = {
      -- server-specific settings
    },
  },
}
```

## Customization

### Adding Plugins

Create a new file in `lua/plugins/` or add to existing category:

```lua
-- lua/plugins/my-plugin.lua
return {
  {
    'author/plugin-name',
    event = 'VeryLazy', -- or cmd, ft, keys, etc.
    opts = {
      -- plugin options
    },
  },
}
```

### Custom Keymaps

Add keymaps in `lua/config/keymap.lua` or use plugin-specific `keys` tables.

### Options

Modify Neovim options in `lua/config/opt.lua`.

## Utilities

### Go Development

```lua
local utils = require('utils')

-- Build Go project with quickfix
utils.go.async_go_build_quickfix()

-- Setup debug configuration
utils.go.setup_go_debug_config()
```

### Database

```lua
local utils = require('utils')

-- Build PostgreSQL connection URL
local url = utils.database.build_pg_url('localhost', '5432', 'user', 'pass', 'dbname')

-- Interactive DB connection prompt
utils.database.prompt_db_connection()
```

### Git

```lua
local utils = require('utils')

-- Open current line's commit in DiffView
utils.git.open_line_commit_diffview()
```

## Performance

This configuration is optimized for fast startup:

- **Lazy loading**: Most plugins load on-demand via events, commands, or filetypes
- **Version pinning**: Critical plugins are version-pinned to avoid breaking changes
- **Modular structure**: Clear separation allows for tree-shaking
- **Async operations**: Heavy operations use `vim.system` instead of blocking `io.popen`

Typical startup time: **< 50ms** (with cached plugins)

## Contributing

Feel free to fork and customize! Key areas for extension:

- Add new language servers in `lsp/`
- Create plugin specs in `lua/plugins/`
- Add utilities in `lua/utils/`
- Customize keymaps in `lua/config/keymap.lua`

## Troubleshooting

### LSP not working

```vim
:checkhealth lsp
```

### Plugins not loading

```vim
:Lazy
```

### Performance issues

```bash
nvim --startuptime startup.log
```

## License

MIT

## Acknowledgments

- [Neovim](https://neovim.io/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) for inspiration
- All plugin authors

## See Also

- [CLAUDE.md](./CLAUDE.md) - AI assistant instructions
- [stylua.toml](./stylua.toml) - Code formatting configuration
