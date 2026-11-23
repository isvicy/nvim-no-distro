-- Async, cached Jujutsu (jj) statusline & buffer diff integration for lualine.nvim
local vcs = require('utils.vcs')

local M = {}

---@type table<string, { text: string, pending: boolean }>
local status_cache = {}
---@type table<string, string>
local workspace_name_cache = {}
---@type table<integer, { root: string, rel_path: string, parent_text: string|nil, stats: table|nil, pending: boolean }>
local diff_cache = {}
---@type table<integer, uv.uv_timer_t>
local debounce_timers = {}

local function refresh_lualine()
  local ok, lualine = pcall(require, 'lualine')
  if ok then
    lualine.refresh({ place = { 'statusline' } })
  end
end

local function compute_diff_stats(parent_text, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_text = table.concat(lines, '\n')
  if #lines > 0 then
    current_text = current_text .. '\n'
  end

  if parent_text == nil then
    -- Brand new file not present in parent revision
    local non_empty = (#lines == 1 and lines[1] == '') and 0 or #lines
    return { added = non_empty, modified = 0, removed = 0 }
  end

  if parent_text == current_text then
    return { added = 0, modified = 0, removed = 0 }
  end

  local hunks = vim.diff(parent_text, current_text, { result_type = 'indices' })
  local added, modified, removed = 0, 0, 0
  for _, hunk in ipairs(hunks) do
    local old_count = hunk[2]
    local new_count = hunk[4]
    if old_count == 0 and new_count > 0 then
      added = added + new_count
    elseif old_count > 0 and new_count == 0 then
      removed = removed + old_count
    else
      local common = math.min(old_count, new_count)
      modified = modified + common
      added = added + (new_count - common)
      removed = removed + (old_count - common)
    end
  end

  return { added = added, modified = modified, removed = removed }
end

local function fetch_workspace_name(root)
  if workspace_name_cache[root] ~= nil then
    return
  end
  workspace_name_cache[root] = ''
  vim.system({
    'jj',
    '--ignore-working-copy',
    '--no-pager',
    '--color=never',
    'workspace',
    'list',
    '-T',
    'if(target.current_working_copy(), name, "")',
  }, { text = true, cwd = root }, function(res)
    if res.code == 0 then
      local name = vim.trim(res.stdout or '')
      workspace_name_cache[root] = name
      vim.schedule(refresh_lualine)
    end
  end)
end

local function format_jj_status(root, raw_stdout)
  local change_id, local_bm, conflict_flag, nearest_bm
  for line in (raw_stdout or ''):gmatch('[^\r\n]+') do
    local parts = vim.split(line, '\t', { plain = true })
    if parts[1] == 'CUR' then
      change_id = parts[2]
      local_bm = parts[3]
      conflict_flag = parts[4]
    elseif parts[1] == 'BM' and (not nearest_bm or nearest_bm == '') then
      nearest_bm = parts[2]
    end
  end

  if not change_id or change_id == '' then
    return ''
  end

  local label
  if local_bm and local_bm ~= '' then
    label = string.format('%s (%s)', local_bm, change_id)
  elseif nearest_bm and nearest_bm ~= '' then
    -- Trim '@origin' suffix if it is the only label for compactness
    local short_bm = nearest_bm:gsub('@[^,]+', '')
    label = string.format('%s → %s', short_bm, change_id)
  else
    label = change_id
  end

  local ws_name = workspace_name_cache[root]
  if ws_name and ws_name ~= '' and ws_name ~= 'default' then
    label = string.format('[%s] %s', ws_name, label)
  end

  if conflict_flag == '1' then
    label = label .. ' !'
  end

  return label
end

local function update_jj_status(root)
  if not root or vim.fn.executable('jj') ~= 1 then
    return
  end

  fetch_workspace_name(root)

  local entry = status_cache[root]
  if entry and entry.pending then
    return
  end
  status_cache[root] = { text = entry and entry.text or '', pending = true }

  local template = 'if(current_working_copy,'
    .. ' "CUR\\t" ++ change_id.short(8) ++ "\\t" ++ local_bookmarks.join(",") ++ "\\t" ++ if(conflict, "1", "0"),'
    .. ' "BM\\t" ++ bookmarks.join(",")) ++ "\\n"'

  vim.system({
    'jj',
    '--ignore-working-copy',
    '--no-pager',
    '--color=never',
    'log',
    '-r',
    '@ | latest(::@ & bookmarks())',
    '--no-graph',
    '-T',
    template,
  }, { text = true, cwd = root }, function(res)
    vim.schedule(function()
      local prev = status_cache[root] and status_cache[root].text or ''
      local text = res.code == 0 and format_jj_status(root, res.stdout) or prev
      status_cache[root] = { text = text, pending = false }
      if text ~= prev then
        refresh_lualine()
      end
    end)
  end)
end

local function update_buf_parent_and_diff(bufnr, root)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= '' then
    return
  end

  local buf_path = vim.api.nvim_buf_get_name(bufnr)
  if buf_path == '' then
    return
  end

  local rel_path = vcs.relative_path(root, buf_path)
  if not rel_path or rel_path == '' then
    return
  end

  local entry = diff_cache[bufnr]
  if entry and entry.pending then
    return
  end
  diff_cache[bufnr] = {
    root = root,
    rel_path = rel_path,
    parent_text = entry and entry.parent_text or nil,
    stats = entry and entry.stats or nil,
    pending = true,
  }

  vim.system({
    'jj',
    '--ignore-working-copy',
    '--no-pager',
    '--color=never',
    'file',
    'show',
    '-r',
    'latest(parents(@), 1)',
    '--',
    rel_path,
  }, { text = true, cwd = root }, function(res)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        diff_cache[bufnr] = nil
        return
      end
      local parent_text = res.code == 0 and (res.stdout or '') or nil
      local stats = compute_diff_stats(parent_text, bufnr)
      diff_cache[bufnr] = {
        root = root,
        rel_path = rel_path,
        parent_text = parent_text,
        stats = stats,
        pending = false,
      }
      refresh_lualine()
    end)
  end)
end

local function recompute_buf_diff(bufnr)
  local entry = diff_cache[bufnr]
  if not entry then
    return
  end
  entry.stats = compute_diff_stats(entry.parent_text, bufnr)
  refresh_lualine()
end

local function schedule_recompute(bufnr)
  local timer = debounce_timers[bufnr]
  if not timer then
    timer = vim.uv.new_timer()
    debounce_timers[bufnr] = timer
  end
  if not timer then
    return
  end
  timer:stop()
  timer:start(
    200,
    0,
    vim.schedule_wrap(function()
      recompute_buf_diff(bufnr)
    end)
  )
end

---@return boolean
function M.is_jj()
  return vcs.is_jj()
end

---@return boolean
function M.is_not_jj()
  return not vcs.is_jj()
end

---@return string
function M.status()
  local kind, root = vcs.root()
  if kind ~= 'jj' or not root then
    return ''
  end
  local entry = status_cache[root]
  if not entry then
    update_jj_status(root)
    return ''
  end
  return entry.text
end

---Unified lualine diff source: uses gitsigns in git repos and cached jj diff in jj repos.
---@return { added: integer, modified: integer, removed: integer }|nil
function M.diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return {
      added = gitsigns.added or 0,
      modified = gitsigns.changed or 0,
      removed = gitsigns.removed or 0,
    }
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local entry = diff_cache[bufnr]
  if entry and entry.stats then
    return entry.stats
  end
  return nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup('LualineJJ', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'DirChanged', 'TermLeave' }, {
    group = group,
    callback = function(args)
      local bufnr = args.buf or vim.api.nvim_get_current_buf()
      local kind, root = vcs.root()
      if kind == 'jj' and root then
        update_jj_status(root)
        update_buf_parent_and_diff(bufnr, root)
      end
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'VcsWorkspaceSwitched',
    callback = function()
      workspace_name_cache = {}
      local kind, root = vcs.root()
      if kind == 'jj' and root then
        update_jj_status(root)
        update_buf_parent_and_diff(vim.api.nvim_get_current_buf(), root)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      local kind, root = vcs.root()
      if kind == 'jj' and root then
        update_jj_status(root)
        if diff_cache[bufnr] then
          recompute_buf_diff(bufnr)
        else
          update_buf_parent_and_diff(bufnr, root)
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function(args)
      if diff_cache[args.buf] then
        schedule_recompute(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args)
      diff_cache[args.buf] = nil
      local timer = debounce_timers[args.buf]
      if timer then
        timer:stop()
        timer:close()
        debounce_timers[args.buf] = nil
      end
    end,
  })

  -- Initial populate if already opened inside a jj repo
  local kind, root = vcs.root()
  if kind == 'jj' and root then
    update_jj_status(root)
    update_buf_parent_and_diff(vim.api.nvim_get_current_buf(), root)
  end
end

return M
