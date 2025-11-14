---@class GitUtils
---@field open_line_commit_diffview function Open current line's commit in DiffView
local M = {}

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

return M
