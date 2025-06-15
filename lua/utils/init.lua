---@class UtilsModule
---@field get_project_root function
---@field clean_host function
---@field build_pg_url function
---@field copy_to_clipboard function
---@field input_with_default function
---@field prompt_db_connection function
---@field copy_diagnostic function
---@field async_go_build_quickfix function
---@field setup_go_debug_config function
---@field print_full_path function
---@field open_line_commit_diffview function

---@field dump function
local M = {}

-- Constants

local CONSTANTS = {

  PROJECT_MARKERS = { '.git', 'go.mod' },
  DEFAULT_DB = {
    HOST = 'localhost',
    PORT = '5432',
    USER = 'postgres',
  },
  GO_BUILD_CMD = 'go build ./...',
  RIPGREP_CMD = "rg --type go 'func\\s+main\\s*\\(' %s -l | xargs -n1 dirname 2>/dev/null | sort | uniq",
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

-- Function to copy text to clipboard

M.copy_to_clipboard = function(text)
  vim.fn.setreg('+', text) -- Copy to system clipboard
  vim.fn.setreg('"', text) -- Copy to unnamed register
end

-- Function to get user input with default value
M.input_with_default = function(prompt, default)
  local result = vim.fn.input(prompt)
  if result == '' then
    return default
  end
  return result
end

-- Function to prompt for database connection details
M.prompt_db_connection = function()
  -- Clear the command line
  vim.cmd('echo ""')

  local host = M.input_with_default('Host (default: localhost): ', 'localhost')
  vim.cmd('echo ""') -- Add newline after input
  local port = M.input_with_default('Port (default: 5432): ', '5432')

  vim.cmd('echo ""')
  local user = M.input_with_default('Username (default: postgres): ', 'postgres')
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
  M.copy_to_clipboard(url)

  vim.cmd('echo ""')
  print('\nConnection URL has been copied to clipboard!')

  vim.cmd('DBUIAddConnection')
  vim.cmd('DBUI')
end

-- Function to copy diagnostic information
M.copy_diagnostic = function()
  local current_line = vim.fn.line('.') - 1
  local current_buf = vim.api.nvim_get_current_buf()

  local diagnostics = vim.diagnostic.get(current_buf, { lnum = current_line })
  if #diagnostics == 0 then
    vim.notify('No diagnostics', vim.log.levels.WARN, { title = 'Copy' })
    return
  end

  local messages = {}
  for _, diagnostic in ipairs(diagnostics) do
    table.insert(messages, diagnostic.message)
  end
  local diagnostic_text = table.concat(messages, '\n')

  -- Copy to system clipboard and unnamed register
  vim.fn.setreg('+', diagnostic_text)
  vim.fn.setreg('"', diagnostic_text)

  -- Use shorter notification without the actual text
  vim.notify('Diagnostic copied', vim.log.levels.INFO, { title = 'Copy' })
end

---Parse Go build error output into quickfix format
---@param stderr_data string[] Raw stderr lines from go build
---@return table[] errors Quickfix-formatted error list
local function parse_go_build_errors(stderr_data)
  local errors = {}
  for _, line in ipairs(stderr_data) do
    -- Match Go error format: file:line:col: message
    local file, lnum, col, msg = line:match('(.+):(%d+):(%d+): (.*)')
    if file and lnum and col and msg then
      table.insert(errors, {
        filename = file,
        lnum = tonumber(lnum),

        col = tonumber(col),
        text = msg,
        type = 'E',
      })
    end
  end
  return errors
end

---Async Go build with quickfix integration
M.async_go_build_quickfix = function()
  -- Clear the quickfix list first
  vim.fn.setqflist({}, 'r')
  vim.notify('Go build started...', vim.log.levels.INFO)

  local stderr_data = {}

  local job = vim.fn.jobstart(CONSTANTS.GO_BUILD_CMD, {
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(stderr_data, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          vim.notify('Build successful!', vim.log.levels.INFO)
          return
        end

        local errors = parse_go_build_errors(stderr_data)
        vim.fn.setqflist(errors)

        if #errors > 0 then
          vim.cmd('copen')
          vim.notify(
            string.format('Build failed with %d errors! Check quickfix list.', #errors),
            vim.log.levels.ERROR
          )
        else
          vim.notify('Build failed but no parseable errors found', vim.log.levels.ERROR)
        end
      end)
    end,
  })

  if job == 0 then
    vim.notify('Failed to start go build', vim.log.levels.ERROR)
  elseif job == -1 then
    vim.notify('Invalid arguments for go build', vim.log.levels.ERROR)
  end
end

---Find Go packages containing main functions
---@param project_root string The project root directory
---@return string[]|nil main_dirs List of directories containing main functions
local function find_go_main_packages(project_root)
  local cmd = string.format(CONSTANTS.RIPGREP_CMD, vim.fn.shellescape(project_root))
  local handle = io.popen(cmd)

  if not handle then
    vim.notify('Failed to search for Go files with main function', vim.log.levels.ERROR)
    return nil
  end

  local ok, result = pcall(handle.read, handle, '*a')
  handle:close()

  if not ok then
    vim.notify('Error reading search results: ' .. result, vim.log.levels.ERROR)
    return nil
  end

  -- Parse results into table
  local main_dirs = {}
  for dir in string.gmatch(result, '([^\n]+)') do
    if dir ~= '' then
      table.insert(main_dirs, dir)
    end
  end

  return main_dirs
end

---Create debug configuration object
---@param choice string The selected package name
---@param selected_dir string The full path to selected directory
---@param args string[] Program arguments
---@return table go_config The debug configuration
local function create_debug_config(choice, selected_dir, args)
  return {

    name = 'Debug Go: ' .. choice,
    type = 'go',
    request = 'launch',
    program = selected_dir,
    args = args,
    env = {
      CGO_ENABLED = '0',
    },
  }
end

---Read or create launch.json configuration
---@param launch_file string Path to launch.json file

---@return table launch_config The launch configuration
local function read_launch_config(launch_file)
  local default_config = {
    version = '0.2.0',
    configurations = {},
  }

  if vim.fn.filereadable(launch_file) ~= 1 then
    return default_config
  end

  local file = io.open(launch_file, 'r')
  if not file then
    vim.notify('Failed to open launch.json for reading', vim.log.levels.WARN)
    return default_config
  end

  local content = file:read('*all')
  file:close()

  local ok, parsed = pcall(vim.fn.json_decode, content)
  if not ok or not parsed then
    vim.notify('Failed to parse launch.json, using default config', vim.log.levels.WARN)
    return default_config
  end

  return parsed
end

---Write launch configuration to file
---@param launch_file string Path to launch.json file
---@param launch_config table The launch configuration

---@return boolean success Whether the write was successful

local function write_launch_config(launch_file, launch_config)
  local file = io.open(launch_file, 'w')
  if not file then
    vim.notify('Failed to write to ' .. launch_file, vim.log.levels.ERROR)
    return false
  end

  local ok, json_str = pcall(vim.fn.json_encode, launch_config)
  if not ok then
    file:close()
    vim.notify('Failed to encode launch config as JSON', vim.log.levels.ERROR)
    return false
  end

  file:write(json_str)
  file:close()

  return true
end

---Set up Go debug configuration
M.setup_go_debug_config = function()
  local project_root = M.get_project_root()
  local main_dirs = find_go_main_packages(project_root)

  if not main_dirs or #main_dirs == 0 then
    vim.notify('No directories with Go main function found', vim.log.levels.WARN)
    return
  end

  -- Prepare selection options with relative paths
  local options = {}

  for _, dir in ipairs(main_dirs) do
    local rel_path = string.gsub(dir, vim.fn.getcwd() .. '/', '')

    table.insert(options, rel_path)
  end

  -- Let user select from list
  vim.ui.select(options, {
    prompt = 'Select main package to debug:',
  }, function(choice, idx)
    if not choice then
      return
    end

    local selected_dir = main_dirs[idx]

    -- Prompt for program arguments
    vim.ui.input({
      prompt = 'Program arguments (space separated):',
      default = vim.g.last_go_debug_args or '',
    }, function(input)
      if input == nil then
        return
      end

      vim.g.last_go_debug_args = input

      -- Parse arguments
      local args = {}
      for arg in string.gmatch(input, '%S+') do
        table.insert(args, arg)
      end

      -- Ensure .vscode directory exists
      local vscode_dir = vim.fn.getcwd() .. '/.vscode'
      if vim.fn.isdirectory(vscode_dir) == 0 then
        vim.fn.mkdir(vscode_dir, 'p')
      end

      local launch_file = vscode_dir .. '/launch.json'
      local launch_config = read_launch_config(launch_file)
      local go_config = create_debug_config(choice, selected_dir, args)

      -- Update or add configuration
      local found = false

      for i, config in ipairs(launch_config.configurations or {}) do
        if config.name == go_config.name then
          launch_config.configurations[i] = go_config
          found = true

          break
        end
      end

      if not found then
        if not launch_config.configurations then
          launch_config.configurations = {}
        end
        table.insert(launch_config.configurations, go_config)
      end

      -- Write configuration and start debug session
      if write_launch_config(launch_file, launch_config) then
        vim.notify('Debug configuration saved to ' .. launch_file, vim.log.levels.INFO)
        vim.cmd("lua require('dap').run({name = 'Debug Go: " .. choice .. "'})")
      end
    end)
  end)
end

-- Function to print full path of current file

M.print_full_path = function()
  local full_path = vim.fn.expand('%:p')

  print(full_path)
  vim.fn.setreg('+', full_path)

  vim.fn.setreg('"', full_path)
end

---Get git blame information for current line

---@param file_path string Path to the file
---@param line_nr number Line number
---@return table|nil blame_info Parsed blame information or nil on error
local function get_git_blame_info(file_path, line_nr)
  local cmd = string.format(
    'git blame -L %d,%d --porcelain %s',
    line_nr,
    line_nr,
    vim.fn.shellescape(file_path)
  )
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to get git blame: ' .. output, vim.log.levels.ERROR)
    return nil
  end

  local commit_hash = output:match('^(%x+)')
  if not commit_hash or commit_hash:match('^0+$') then
    vim.notify('Could not find commit hash or line not yet committed', vim.log.levels.ERROR)
    return nil
  end

  return {
    commit_hash = commit_hash,
    summary = output:match('summary (.+)'),

    author = output:match('author (.+)'),
    author_time = output:match('author%-time (%d+)'),
  }
end

---Open line commit in DiffView
---@return boolean success Whether the operation was successful

M.open_line_commit_diffview = function()
  local file_path = vim.fn.expand('%:p')
  if file_path == '' then
    vim.notify('Not in file buffer', vim.log.levels.ERROR)
    return false
  end

  local line_nr = vim.fn.line('.')
  local blame_info = get_git_blame_info(file_path, line_nr)

  if not blame_info then
    return false
  end

  -- Show commit info if available
  if blame_info.summary and blame_info.author and blame_info.author_time then
    local date = os.date('%Y-%m-%d %H:%M:%S', tonumber(blame_info.author_time))
    vim.notify(
      string.format(
        'Opening commit: %s\nAuthor: %s\nDate: %s\nDescription: %s',
        blame_info.commit_hash:sub(1, 8),
        blame_info.author,
        date,
        blame_info.summary
      ),
      vim.log.levels.INFO
    )
  end

  -- Open DiffView to view the commit
  local ok, err =
    pcall(vim.cmd, 'DiffviewOpen ' .. blame_info.commit_hash .. '~1..' .. blame_info.commit_hash)
  if not ok then
    vim.notify('Failed to open DiffView: ' .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

M.dump = function(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then
        k = '"' .. k .. '"'
      end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

return M
