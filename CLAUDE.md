# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Neovim configuration repository structured as a modular Lua-based setup. The configuration follows modern Neovim practices with lazy loading and plugin management.

### Core Structure
- `init.lua` - Entry point that loads all configuration modules
- `lua/config/` - Core configuration modules (options, keymaps, commands, plugin manager)
- `lua/plugins/` - Plugin specifications organized by functionality
- `lsp/` - Language server configurations (gopls, lua_ls)
- `lua/utils/` - Utility functions and helper modules

### Key Components

**Plugin Management**: Uses lazy.nvim for plugin management with automatic bootstrapping. All plugins are defined in `lua/plugins/` with lazy loading based on events, file types, and key mappings.

**LSP Configuration**: Language servers are configured in separate files under `lsp/` directory. Currently supports Go (gopls) and Lua (lua_ls) with comprehensive settings for analysis, hints, and code actions.

**Utility Functions**: The `lua/utils/init.lua` module provides Go-specific development utilities including:
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
- Custom keymaps for Go-specific actions (`<leader>cgb` for build, `<leader>cds` for debug setup)

### Key Mappings

**Leader Key**: Space (` `)
**Custom Keymaps**:
- `<leader>v` - Go to definition in vertical split
- `<leader>cgb` - Run Go build
- `<leader>ccd` - Copy diagnostic message
- `<leader>gld` - View current line's commit diff
- `<leader>p` / `<leader>P` - Paste from yank register (not delete register)

### LSP Integration

The configuration uses Neovim's built-in LSP client with enhanced features:
- Document highlighting on cursor hold
- Custom diagnostic formatting with source and code
- Glance.nvim for definition/reference previews
- Goto-preview for floating window previews
- Diagflow for better diagnostic display

### File Organization

Plugins are organized by functionality:
- `ai.lua` - AI-related plugins
- `blink.lua` - Completion engine
- `colorscheme.lua` - Color scheme configuration
- `dap.lua` - Debug Adapter Protocol
- `editor.lua` - Editor enhancements
- `git.lua` - Git integration
- `ui.lua` - UI improvements
- `lsp/init.lua` - LSP configuration and plugins