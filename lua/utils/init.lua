---@class UtilsModule
---@field get_project_root function Get the project root directory
---@field copy_to_clipboard function Copy text to clipboard
---@field print_full_path function Print and copy current file's full path
---@field copy_diagnostic function Copy diagnostic information
---@field dump function Dump table to string for debugging
---@field go GoUtils Go development utilities
---@field database DatabaseUtils Database connection utilities
---@field git GitUtils Git integration utilities
local M = {}

-- Constants

local CONSTANTS = {
  PROJECT_MARKERS = { '.git', 'go.mod' },
}

---Get the project root directory by searching for markers
---@return string project_root The path to project root
M.get_project_root = function()
  local current_dir = vim.fn.getcwd()
  local potential_root = current_dir

  -- Search upward for project markers

  while potential_root ~= '/' do
    for _, marker in ipairs(CONSTANTS.PROJECT_MARKERS) do
      local marker_path = potential_root .. '/' .. marker
      local is_found = (marker == '.git' and vim.fn.isdirectory(marker_path) == 1)
        or (marker ~= '.git' and vim.fn.filereadable(marker_path) == 1)

      if is_found then
        vim.notify(
          string.format('Found project root (%s): %s', marker, potential_root),
          vim.log.levels.INFO
        )
        return potential_root
      end
    end

    -- Move to parent directory

    potential_root = vim.fn.fnamemodify(potential_root, ':h')
  end

  -- If not found, return current directory
  vim.notify('No project root found, using current directory: ' .. current_dir, vim.log.levels.WARN)
  return current_dir
end

---Copy text to clipboard
---@param text string The text to copy
M.copy_to_clipboard = function(text)
  vim.fn.setreg('+', text) -- Copy to system clipboard
  vim.fn.setreg('"', text) -- Copy to unnamed register
end

---Copy diagnostic information for current line
M.copy_diagnostic = function()
  local current_line = vim.fn.line('.') - 1
  local current_buf = vim.api.nvim_get_current_buf()

  local diagnostics = vim.diagnostic.get(current_buf, { lnum = current_line })
  if #diagnostics == 0 then
    vim.notify('No diagnostic at current line', vim.log.levels.WARN)
    return
  end

  -- If there's only one diagnostic, copy directly
  if #diagnostics == 1 then
    M.copy_to_clipboard(diagnostics[1].message)
    vim.notify('Diagnostic copied to clipboard', vim.log.levels.INFO)
    return
  end

  -- If there are multiple diagnostics, let user choose
  local items = {}
  for i, diagnostic in ipairs(diagnostics) do
    table.insert(
      items,
      string.format('%d. [%s] %s', i, diagnostic.source or 'unknown', diagnostic.message)
    )
  end

  vim.ui.select(items, {
    prompt = 'Select diagnostic to copy:',
  }, function(choice, idx)
    if choice then
      M.copy_to_clipboard(diagnostics[idx].message)
      vim.notify('Diagnostic copied to clipboard', vim.log.levels.INFO)
    end
  end)
end

---Print and copy current file's full path
M.print_full_path = function()
  local full_path = vim.fn.expand('%:p')
  print(full_path)
  vim.fn.setreg('+', full_path)
  vim.fn.setreg('"', full_path)
end

---Dump table to string for debugging
---@param o any The object to dump
---@return string The string representation
M.dump = function(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then
        k = '"' .. k .. '"'
      end
      s = s .. '[' .. k .. '] = ' .. M.dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

-- Load and export sub-modules
M.go = require('utils.go')
M.database = require('utils.database')
M.git = require('utils.git')

-- Export sub-module functions at top level for backward compatibility
M.async_go_build_quickfix = M.go.async_go_build_quickfix
M.setup_go_debug_config = M.go.setup_go_debug_config

M.clean_host = M.database.clean_host
M.build_pg_url = M.database.build_pg_url
M.input_with_default = M.database.input_with_default
M.prompt_db_connection = M.database.prompt_db_connection

M.open_line_commit_diffview = M.git.open_line_commit_diffview

return M
