---@class DatabaseUtils
---@field clean_host function Clean host string by removing protocol
---@field build_pg_url function Build PostgreSQL connection URL
---@field input_with_default function Get user input with default value
---@field prompt_db_connection function Prompt for database connection details
local M = {}

local CONSTANTS = {
  DEFAULT_DB = {
    HOST = 'localhost',
    PORT = '5432',
    USER = 'postgres',
  },
}

---Clean host string by removing protocol and trailing slashes
---@param host string The host string to clean
---@return string cleaned_host The cleaned host string
M.clean_host = function(host)
  if not host or type(host) ~= 'string' or host == '' then
    error('Host must be a non-empty string')
  end
  -- First remove http(s):// prefix, then remove trailing slashes
  return host:gsub('^https?://', ''):gsub('/*$', '')
end

---Build PostgreSQL connection URL
---@param host string Database host
---@param port string Database port
---@param user string Database user
---@param password string Database password
---@param dbname string Database name
---@return string connection_url The PostgreSQL connection URL
M.build_pg_url = function(host, port, user, password, dbname)
  local required_params =
    { host = host, port = port, user = user, password = password, dbname = dbname }

  for param_name, param_value in pairs(required_params) do
    if not param_value or param_value == '' then
      error(string.format("Parameter '%s' cannot be empty", param_name))
    end
  end

  local ok, cleaned_host = pcall(M.clean_host, host)
  if not ok then
    error('Failed to clean host: ' .. cleaned_host)
  end

  return string.format('postgres://%s:%s@%s:%s/%s', user, password, cleaned_host, port, dbname)
end

---Get user input with default value
---@param prompt string The prompt to display
---@param default string The default value
---@return string The user input or default value
M.input_with_default = function(prompt, default)
  local result = vim.fn.input(prompt)
  if result == '' then
    return default
  end
  return result
end

---Prompt for database connection details
M.prompt_db_connection = function()
  local utils = require('utils')

  -- Clear the command line
  vim.cmd('echo ""')

  local host = M.input_with_default('Host (default: localhost): ', CONSTANTS.DEFAULT_DB.HOST)
  vim.cmd('echo ""') -- Add newline after input
  local port = M.input_with_default('Port (default: 5432): ', CONSTANTS.DEFAULT_DB.PORT)

  vim.cmd('echo ""')
  local user = M.input_with_default('Username (default: postgres): ', CONSTANTS.DEFAULT_DB.USER)
  vim.cmd('echo ""')
  local password = vim.fn.inputsecret('Password: ')
  vim.cmd('echo ""')
  if password == '' then
    print('Password cannot be empty')
    return
  end
  local dbname = vim.fn.input('Database name: ')
  vim.cmd('echo ""')
  if dbname == '' then
    print('Database name cannot be empty')
    return
  end

  -- Build the URL

  local url = M.build_pg_url(host, port, user, password, dbname)

  -- Copy URL to clipboard
  utils.copy_to_clipboard(url)

  vim.cmd('echo ""')
  print('\nConnection URL has been copied to clipboard!')

  vim.cmd('DBUIAddConnection')
  vim.cmd('DBUI')
end

return M
