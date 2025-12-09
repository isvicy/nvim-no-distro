# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Development Commands

### Code Formatting

- **Lua formatting**: Uses `stylua` with configuration in `stylua.toml`
- **Go formatting**: Uses `gofumpt` and `goimports` via conform.nvim
- **Format on save**: Enabled for most file types (disabled for C/C++)
- **Manual format**: `<leader>fm` or `:ConformInfo`

### Custom Commands

- `:GoBuild` - Async Go build with quickfix integration
- `:GoDebugSetup` - Interactive Go debug configuration setup
- `:CopyDiagnostic` - Copy LSP diagnostic messages to clipboard
- `:DiffViewLineCommit` - View git blame commit diff for current line
- `:DBUIPrompt` - Interactive database connection setup
- `:PrintFullPath` - Print and copy current file's full path

## Architecture Overview

This is a Neovim configuration repository structured as a modular Lua-based
setup. The configuration follows modern Neovim practices with lazy loading and
plugin management.

### Core Structure

- `init.lua` - Entry point that loads all configuration modules in order
- `lua/config/` - Core configuration modules (options, keymaps, commands, plugin
  manager)
- `lua/plugins/` - Plugin specifications organized by functionality with lazy
  loading
- `lsp/` - Language server configurations (gopls, lua_ls, ty.lua)
- `lua/utils/` - Utility functions and helper modules for Go development

### Key Components

**Plugin Management**: Uses lazy.nvim for plugin management with automatic
bootstrapping. All plugins are defined in `lua/plugins/` with lazy loading based
on events, file types, and key mappings.

**LSP Configuration**: Language servers are configured in separate files under
`lsp/` directory. Currently supports Go (gopls) and Lua (lua_ls) with
comprehensive settings for analysis, hints, and code actions.

**Utility Functions**: The `lua/utils/init.lua` module provides Go-specific
development utilities including:

- Project root detection
- PostgreSQL connection URL building
- Async Go build with quickfix integration
- Go debug configuration setup for DAP
- Git blame integration with DiffView

**Custom Commands**: Several custom commands are registered for Go development:

- `:GoBuild` - Async Go build with error parsing
- `:GoDebugSetup` - Interactive debug configuration setup
- `:CopyDiagnostic` - Copy LSP diagnostic messages
- `:DiffViewLineCommit` - View git blame commit in DiffView

### Go Development Features

The configuration includes specialized Go development tools:

- Automatic main package detection for debugging
- VSCode-compatible launch.json generation
- Quickfix integration for build errors
- Custom keymaps for Go-specific actions (`<leader>cgb` for build, `<leader>cds`
  for debug setup)

### Key Mappings

**Leader Key**: Space (``)

**Core Navigation & Editing**:

- `<C-h/j/k/l>` - Window navigation
- `<leader>v` - Go to definition in vertical split
- `<leader>p` / `<leader>P` - Paste from yank register (not delete register)
- `Y` - Yank to end of line
- `n/N` - Search with auto-center
- `*` - Highlight word under cursor without jumping
- Arrow keys - Window resizing

**Go Development**:

- `<leader>cgb` - Run Go build with quickfix
- `<leader>cds` - Setup Go debug configuration

**LSP & Diagnostics** (on LSP attach):

- `gd` - Go to definition (FzfLua)
- `gr` - Go to references (FzfLua)
- `gI` - Go to implementation (FzfLua)
- `gy` - Go to type definition (FzfLua)
- `gl` - Open diagnostic float
- `K` - Hover documentation
- `<leader>cr` - Rename symbol
- `<leader>ca` - Code actions
- `<leader>cf` - Format buffer
- `<leader>ccd` - Copy diagnostic message
- `<leader>fm` - Format buffer (conform.nvim)

**Git Integration**:

- `<leader>gld` - View current line's commit diff

### LSP Integration

The configuration uses Neovim's built-in LSP client with enhanced features:

- Document highlighting on cursor hold
- Custom diagnostic formatting with source and code
- Glance.nvim for definition/reference previews
- Goto-preview for floating window previews
- Diagflow for better diagnostic display

### File Organization

**Config Modules** (`lua/config/`):

- `opt.lua` - Neovim options and settings
- `keymap.lua` - Base keymaps and utilities
- `autocmd.lua` - Autocommands and user commands
- `lsp.lua` - LSP base configuration
- `lazy.lua` - Plugin manager setup

**Plugin Specifications** (`lua/plugins/`):

- `ai.lua` - AI-related plugins
- `blink.lua` - Completion engine configuration
- `clipboard.lua` - System clipboard integration
- `colorscheme.lua` - Color scheme configuration
- `conform.lua` - Code formatting (stylua, gofumpt, goimports)
- `dap.lua` - Debug Adapter Protocol
- `editor.lua` - Editor enhancements
- `explorer.lua` - File explorer configuration
- `git.lua` - Git integration (diffview, gitsigns)
- `lint.lua` - Linting configuration
- `ui.lua` - UI improvements and dashboard
- `vim-sleuth.lua` - Automatic indentation detection
- `lsp/init.lua` - LSP plugins and configuration

### Automatic Behaviors

- **File directory opening**: Automatically opens FzfLua file finder when
  opening a directory
- **Format on save**: Enabled for Lua and Go files via conform.nvim
- **Lint on save**: Automated linting on buffer events via nvim-lint
- **LSP document highlighting**: Highlights symbol instances on cursor hold
- **Yank highlighting**: Brief highlight when copying text

