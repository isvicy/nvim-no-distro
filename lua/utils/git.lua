---@class GitUtils
---@field open_line_commit_diffview function Open current line's commit in DiffView
local M = {}

local vcs = require('utils.vcs')

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

---Get jj annotate information for current line
---@param jj_root string Path to jj workspace root
---@param file_path string Path to the file
---@param line_nr number Line number
---@return table|nil blame_info Parsed blame information or nil on error
local function get_jj_blame_info(jj_root, file_path, line_nr)
  local rel_path = vcs.relative_path(jj_root, file_path)
  if not rel_path or rel_path == '' then
    vim.notify('File is outside jj workspace root', vim.log.levels.ERROR)
    return nil
  end

  local template = 'commit.commit_id() ++ "\\t" ++ commit.change_id().short(8) ++ "\\t"'
    .. ' ++ commit.author().name() ++ "\\t"'
    .. ' ++ commit.author().timestamp().format("%Y-%m-%d %H:%M:%S") ++ "\\t"'
    .. ' ++ commit.description().first_line() ++ "\\n"'

  local res = vcs.jj_run({ 'file', 'annotate', '-T', template, '--', rel_path }, { cwd = jj_root })
  if res.code ~= 0 then
    vim.notify(
      'Failed to get jj annotate: ' .. vim.trim(res.stderr or res.stdout or ''),
      vim.log.levels.ERROR
    )
    return nil
  end

  local lines = vim.split(res.stdout or '', '\n', { plain = true })
  local line = lines[line_nr]
  if not line or line == '' then
    vim.notify('Could not find jj annotation for current line', vim.log.levels.ERROR)
    return nil
  end

  local parts = vim.split(line, '\t', { plain = true })
  local commit_hash = parts[1]
  if not commit_hash or commit_hash == '' then
    vim.notify('Could not extract commit id from jj annotate', vim.log.levels.ERROR)
    return nil
  end

  local parent_res = vcs.jj_run({
    'log',
    '-r',
    string.format('latest(parents(commit_id("%s")), 1)', commit_hash),
    '--no-graph',
    '-T',
    'commit_id ++ "\\n"',
  }, { cwd = jj_root })
  local parent_hash = parent_res.code == 0 and vim.trim(parent_res.stdout or ''):match('^(%x+)')
    or 'root()'

  return {
    commit_hash = commit_hash,
    parent_hash = parent_hash,
    change_id = parts[2],
    author = parts[3],
    date = parts[4],
    summary = parts[5],
  }
end

---Open line commit in DiffView (supports both git and jj)
---@return boolean success Whether the operation was successful
M.open_line_commit_diffview = function()
  local file_path = vim.fn.expand('%:p')
  if file_path == '' then
    vim.notify('Not in file buffer', vim.log.levels.ERROR)
    return false
  end

  local line_nr = vim.fn.line('.')
  local kind, root = vcs.root(file_path)

  if kind == 'jj' and root then
    local blame_info = get_jj_blame_info(root, file_path, line_nr)
    if not blame_info then
      return false
    end

    vim.notify(
      string.format(
        'Opening change: %s (%s)\nAuthor: %s\nDate: %s\nDescription: %s',
        blame_info.change_id or '',
        blame_info.commit_hash:sub(1, 8),
        blame_info.author or '',
        blame_info.date or '',
        blame_info.summary or '(no description)'
      ),
      vim.log.levels.INFO
    )

    local ok, err =
      pcall(vim.cmd, 'DiffviewOpen ' .. blame_info.parent_hash .. '..' .. blame_info.commit_hash)
    if not ok then
      vim.notify('Failed to open DiffView: ' .. err, vim.log.levels.ERROR)
      return false
    end
    return true
  end

  local blame_info = get_git_blame_info(file_path, line_nr)
  if not blame_info then
    return false
  end

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

  local ok, err =
    pcall(vim.cmd, 'DiffviewOpen ' .. blame_info.commit_hash .. '~1..' .. blame_info.commit_hash)
  if not ok then
    vim.notify('Failed to open DiffView: ' .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

return M
