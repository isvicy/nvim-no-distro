---@class GoUtils
---@field async_go_build_quickfix function Build Go project asynchronously with quickfix integration
---@field setup_go_debug_config function Setup Go debug configuration interactively
local M = {}

local CONSTANTS = {
  GO_BUILD_CMD = 'go build ./...',
  RIPGREP_CMD = "rg --type go 'func\\s+main\\s*\\(' %s -l | xargs -n1 dirname 2>/dev/null | sort | uniq",
}

---Find Go packages containing main functions
---@param project_root string The project root directory
---@return string[]|nil main_dirs List of directories containing main functions
local function find_go_main_packages(project_root)
  local cmd = string.format(CONSTANTS.RIPGREP_CMD, vim.fn.shellescape(project_root))
  local result = vim.system({ 'sh', '-c', cmd }, { text = true }):wait()

  if result.code ~= 0 then
    vim.notify('Failed to search for Go main packages', vim.log.levels.ERROR)
    return nil
  end

  if not result.stdout or result.stdout == '' then
    vim.notify('No Go files with main function found', vim.log.levels.WARN)
    return nil
  end

  local main_dirs = {}
  for line in result.stdout:gmatch('[^\r\n]+') do
    if line ~= '' then
      table.insert(main_dirs, line)
    end
  end

  if #main_dirs == 0 then
    vim.notify('No Go main packages found', vim.log.levels.WARN)
    return nil
  end

  return main_dirs
end

---Run Go build asynchronously and populate quickfix on errors
M.async_go_build_quickfix = function()
  local cmd = CONSTANTS.GO_BUILD_CMD
  vim.notify('Building Go project...', vim.log.levels.INFO)

  -- Parse go build errors
  local function parse_go_errors(lines)
    local errors = {}
    local current_error = nil

    for _, line in ipairs(lines) do
      -- Match Go error format: filename:line:col: message
      local filename, lnum, col, msg = line:match('^([^:]+):(%d+):(%d+): (.+)$')

      if filename and lnum and col and msg then
        current_error = {
          filename = filename,
          lnum = tonumber(lnum),
          col = tonumber(col),
          text = msg,
          type = 'E',
        }
        table.insert(errors, current_error)
      elseif current_error and line:match('^%s+') then
        -- Continuation line (indented)
        current_error.text = current_error.text .. ' ' .. vim.trim(line)
      end
    end

    return errors
  end

  local error_lines = {}
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= '' then
          table.insert(error_lines, line)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line ~= '' then
          table.insert(error_lines, line)
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify('Build succeeded!', vim.log.levels.INFO)
        vim.fn.setqflist({}, 'r') -- Clear quickfix
      else
        local errors = parse_go_errors(error_lines)

        if #errors > 0 then
          vim.fn.setqflist(errors, 'r')
          vim.cmd('copen')
          vim.notify(
            string.format('Build failed with %d error(s). See quickfix for details.', #errors),
            vim.log.levels.ERROR
          )
        else
          vim.notify('Build failed but no parseable errors found', vim.log.levels.ERROR)
        end
      end
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })

  if job_id <= 0 then
    vim.notify('Failed to start build job', vim.log.levels.ERROR)
  end
end

---Setup Go debug configuration interactively
M.setup_go_debug_config = function()
  local project_root = require('utils').get_project_root()

  -- Find Go packages with main functions
  local main_dirs = find_go_main_packages(project_root)

  if not main_dirs or #main_dirs == 0 then
    vim.notify('No main packages found to debug', vim.log.levels.ERROR)
    return
  end

  -- Convert to relative paths for display
  local choices = {}
  for _, dir in ipairs(main_dirs) do
    local relative_path = vim.fn.fnamemodify(dir, ':~:.')
    table.insert(choices, relative_path)
  end

  -- Prepend index numbers for easy selection
  for i, choice in ipairs(choices) do
    choices[i] = string.format('%d. %s', i, choice)
  end

  -- Prompt user to select main package
  local prompt_lines = { 'Select the main package to debug:' }
  for _, choice in ipairs(choices) do
    table.insert(prompt_lines, choice)
  end
  table.insert(prompt_lines, '')
  table.insert(prompt_lines, 'Enter the number of your choice:')

  -- Display prompt
  for _, line in ipairs(prompt_lines) do
    vim.cmd('echo ""')
    vim.cmd('echohl Question')
    vim.cmd(string.format('echo "%s"', line:gsub('"', '\\"')))
    vim.cmd('echohl None')
  end

  -- Get user input
  local ok, input = pcall(vim.fn.input, '')
  if not ok or not input or input == '' then
    vim.notify('Debug setup cancelled', vim.log.levels.WARN)
    return
  end

  local choice_num = tonumber(input)
  if not choice_num or choice_num < 1 or choice_num > #main_dirs then
    vim.notify('Invalid selection', vim.log.levels.ERROR)
    return
  end

  local selected_dir = main_dirs[choice_num]

  -- Create launch.json compatible with VSCode and nvim-dap
  local dap_config = {
    version = '0.2.0',
    configurations = {
      {
        type = 'go',
        name = 'Debug (from launch.json)',
        request = 'launch',
        mode = 'debug',
        program = selected_dir,
      },
    },
  }

  -- Write to .vscode/launch.json
  local vscode_dir = project_root .. '/.vscode'
  local launch_json_path = vscode_dir .. '/launch.json'

  -- Ensure .vscode directory exists
  if vim.fn.isdirectory(vscode_dir) == 0 then
    local ok_mkdir = pcall(vim.fn.mkdir, vscode_dir, 'p')
    if not ok_mkdir then
      vim.notify('Failed to create .vscode directory', vim.log.levels.ERROR)
      return
    end
  end

  -- Write launch.json
  local json_content = vim.fn.json_encode(dap_config)
  local file = io.open(launch_json_path, 'w')
  if not file then
    vim.notify('Failed to write launch.json', vim.log.levels.ERROR)
    return
  end

  file:write(json_content)
  file:close()

  vim.notify('Debug configuration created: ' .. launch_json_path, vim.log.levels.INFO)
  vim.notify('Selected program: ' .. selected_dir, vim.log.levels.INFO)
end

return M
