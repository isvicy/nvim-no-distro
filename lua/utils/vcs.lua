---@class VcsUtils
local M = {}

local function normalize_dir(path)
  if not path or path == '' then
    return vim.uv.cwd()
  end
  if vim.startswith(path, 'jj://') or vim.startswith(path, 'diffview://') then
    return vim.uv.cwd()
  end
  local stat = vim.uv.fs_stat(path)
  if stat and stat.type == 'directory' then
    return path
  end
  local dir = vim.fn.fnamemodify(path, ':p:h')
  if dir ~= '' and vim.uv.fs_stat(dir) then
    return dir
  end
  return vim.uv.cwd()
end

---Detect VCS type and root directory for a path (defaults to current buffer or cwd).
---When both .jj and .git exist at the same level (colocated), prefers 'jj'.
---@param path? string
---@return 'jj'|'git'|nil vcs
---@return string|nil root
function M.root(path)
  if not path then
    local buf_name = vim.api.nvim_buf_get_name(0)
    path = buf_name ~= '' and buf_name or vim.uv.cwd()
  end

  local start = normalize_dir(path)
  if not start then
    return nil, nil
  end

  local jj_root = vim.fs.root(start, '.jj')
  local git_root = vim.fs.root(start, '.git')

  if jj_root and git_root then
    if #jj_root >= #git_root then
      return 'jj', jj_root
    end
    return 'git', git_root
  end

  if jj_root then
    return 'jj', jj_root
  end
  if git_root then
    return 'git', git_root
  end
  return nil, nil
end

---@param path? string
---@return boolean
function M.is_jj(path)
  local vcs = M.root(path)
  return vcs == 'jj'
end

---@param path? string
---@return boolean
function M.is_git(path)
  local vcs = M.root(path)
  return vcs == 'git'
end

---Run a jj command synchronously via vim.system.
---@param args string[]
---@param opts? { cwd?: string, ignore_wc?: boolean }
---@return vim.SystemCompleted
function M.jj_run(args, opts)
  opts = opts or {}
  local cmd = { 'jj', '--no-pager', '--color=never' }
  if opts.ignore_wc ~= false then
    table.insert(cmd, '--ignore-working-copy')
  end
  vim.list_extend(cmd, args)
  return vim.system(cmd, { text = true, cwd = opts.cwd or vim.uv.cwd() }):wait()
end

---Compute a repo-relative path for a file inside root.
---@param root string
---@param file_path string
---@return string|nil
function M.relative_path(root, file_path)
  local real_root = vim.uv.fs_realpath(root) or vim.fs.normalize(root)
  local real_file = vim.uv.fs_realpath(file_path) or vim.fs.normalize(file_path)
  real_root = real_root:gsub('/+$', '')
  if real_file == real_root then
    return ''
  end
  local prefix = real_root .. '/'
  if vim.startswith(real_file, prefix) then
    return real_file:sub(#prefix + 1)
  end
  return nil
end

---Quote a jj revset symbol (bookmark/tag) if needed.
---@param rev string
---@return string
local function format_jj_revset(rev)
  if rev == '@' or rev == '@-' then
    return rev
  end
  local name, remote = rev:match('^(.-)@([^@]+)$')
  if name and remote then
    return string.format('"%s"@%s', name:gsub('"', '\\"'), remote)
  end
  return string.format('"%s"', rev:gsub('"', '\\"'))
end

---List jj workspaces with name, absolute root, change_id, description, and current flag.
---@param jj_root string
---@return table[]|nil workspaces
---@return string|nil err
function M.jj_list_workspaces(jj_root)
  local template = 'name ++ "\\t" ++ root ++ "\\t" ++ target.change_id().short(8) ++ "\\t"'
    .. ' ++ if(target.current_working_copy(), "1", "0") ++ "\\t"'
    .. ' ++ target.description().first_line() ++ "\\n"'
  local res = M.jj_run({ 'workspace', 'list', '-T', template }, { cwd = jj_root })
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or res.stdout or 'Failed to list jj workspaces')
  end

  local workspaces = {}
  for line in (res.stdout or ''):gmatch('[^\r\n]+') do
    local parts = vim.split(line, '\t', { plain = true })
    if parts[1] and parts[2] and parts[2] ~= '' then
      table.insert(workspaces, {
        name = parts[1],
        root = vim.fs.normalize(parts[2]),
        change_id = parts[3] or '',
        is_current = parts[4] == '1',
        description = parts[5] or '',
      })
    end
  end
  return workspaces, nil
end

local function switch_to_jj_workspace(prev_root, target_ws)
  if not vim.uv.fs_stat(target_ws.root) then
    vim.notify('Workspace directory does not exist: ' .. target_ws.root, vim.log.levels.ERROR)
    return
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  local rel_file = (current_file ~= '' and prev_root) and M.relative_path(prev_root, current_file)
    or nil

  vim.cmd.cd(vim.fn.fnameescape(target_ws.root))
  vim.cmd('clearjumps')

  if rel_file and rel_file ~= '' then
    local candidate = target_ws.root .. '/' .. rel_file
    if vim.uv.fs_stat(candidate) then
      vim.cmd.edit(vim.fn.fnameescape(candidate))
    end
  end

  vim.api.nvim_exec_autocmds('User', {
    pattern = 'VcsWorkspaceSwitched',
    data = { prev_path = prev_root, path = target_ws.root, name = target_ws.name, vcs = 'jj' },
  })
  vim.notify(string.format('Switched to jj workspace: %s (%s)', target_ws.name, target_ws.root))
end

local function create_jj_workspace(jj_root)
  local fzf = require('fzf-lua')

  local entries = {
    '@\t(current working copy)',
    '@-\t(parent of working copy)',
  }
  local seen = { ['@'] = true, ['@-'] = true }

  local bm_res = M.jj_run({
    'bookmark',
    'list',
    '-a',
    '-T',
    'name ++ if(remote, "@" ++ remote, "") ++ "\\n"',
  }, { cwd = jj_root })
  if bm_res.code == 0 then
    for line in (bm_res.stdout or ''):gmatch('[^\r\n]+') do
      local rev = vim.trim(line)
      if rev ~= '' and not seen[rev] then
        seen[rev] = true
        table.insert(entries, rev)
      end
    end
  end

  local tag_res = M.jj_run({ 'tag', 'list', '-T', 'name ++ "\\n"' }, { cwd = jj_root })
  if tag_res.code == 0 then
    for line in (tag_res.stdout or ''):gmatch('[^\r\n]+') do
      local rev = vim.trim(line)
      if rev ~= '' and not seen[rev] then
        seen[rev] = true
        table.insert(entries, rev)
      end
    end
  end

  fzf.fzf_exec(entries, {
    prompt = 'Select base revision (bookmark/tag): ',
    actions = {
      ['default'] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local rev = selected[1]:match('^([^\t]+)')
        if not rev or rev == '' then
          return
        end

        local parent_dir = vim.fn.fnamemodify(jj_root, ':h') .. '/'
        vim.ui.input(
          { prompt = 'Enter jj workspace path: ', default = parent_dir, completion = 'dir' },
          function(input)
            if not input or vim.trim(input) == '' or vim.trim(input) == parent_dir then
              vim.notify('Workspace creation cancelled', vim.log.levels.INFO)
              return
            end

            local dest = vim.fs.normalize(vim.fn.fnamemodify(vim.trim(input), ':p'))
            dest = dest:gsub('/+$', '')

            local res = M.jj_run(
              { 'workspace', 'add', dest, '-r', format_jj_revset(rev) },
              { cwd = jj_root, ignore_wc = false }
            )
            if res.code ~= 0 then
              vim.notify(
                'Failed to create jj workspace: ' .. vim.trim(res.stderr or res.stdout or ''),
                vim.log.levels.ERROR
              )
              return
            end

            local ws_name = vim.fn.fnamemodify(dest, ':t')
            vim.notify('Created jj workspace: ' .. ws_name .. ' (' .. dest .. ')')
            switch_to_jj_workspace(jj_root, { name = ws_name, root = dest })
          end
        )
      end,
    },
  })
end

local function switch_jj_workspace(jj_root)
  local fzf = require('fzf-lua')
  local workspaces, err = M.jj_list_workspaces(jj_root)
  if not workspaces then
    vim.notify(err or 'Failed to list jj workspaces', vim.log.levels.ERROR)
    return
  end

  local items = {}
  local by_line = {}
  for _, ws in ipairs(workspaces) do
    local marker = ws.is_current and '* ' or '  '
    local desc = ws.description ~= '' and ('  ' .. ws.description) or ''
    local line = string.format('%s%s\t%s\t[%s]%s', marker, ws.name, ws.root, ws.change_id, desc)
    table.insert(items, line)
    by_line[line] = ws
  end

  fzf.fzf_exec(items, {
    prompt = 'Select jj workspace to switch to: ',
    actions = {
      ['default'] = function(selected)
        local ws = selected and by_line[selected[1]]
        if not ws then
          return
        end
        if ws.is_current then
          vim.notify('Already in jj workspace: ' .. ws.name, vim.log.levels.INFO)
          return
        end
        switch_to_jj_workspace(jj_root, ws)
      end,
    },
  })
end

local function delete_jj_workspace(jj_root)
  local fzf = require('fzf-lua')
  local workspaces, err = M.jj_list_workspaces(jj_root)
  if not workspaces then
    vim.notify(err or 'Failed to list jj workspaces', vim.log.levels.ERROR)
    return
  end

  local items = {}
  local by_line = {}
  local primary_root = nil
  for _, ws in ipairs(workspaces) do
    local is_primary = vim.fn.isdirectory(ws.root .. '/.jj/repo') == 1
    if is_primary then
      primary_root = ws.root
    end
    local marker = ws.is_current and '* ' or '  '
    local tag = is_primary and ' (primary)' or ''
    local line = string.format('%s%s%s\t%s\t[%s]', marker, ws.name, tag, ws.root, ws.change_id)
    table.insert(items, line)
    by_line[line] = ws
  end

  fzf.fzf_exec(items, {
    prompt = 'Select jj workspace to delete: ',
    actions = {
      ['default'] = function(selected)
        local ws = selected and by_line[selected[1]]
        if not ws then
          return
        end

        if vim.fn.isdirectory(ws.root .. '/.jj/repo') == 1 then
          vim.notify(
            string.format(
              "Cannot delete primary workspace '%s': it owns the shared .jj/repo store.",
              ws.name
            ),
            vim.log.levels.ERROR
          )
          return
        end

        vim.ui.input({
          prompt = string.format(
            "Forget and delete jj workspace '%s' (%s)? (y/N): ",
            ws.name,
            ws.root
          ),
        }, function(input)
          if not input or input:lower() ~= 'y' then
            vim.notify('Workspace deletion cancelled', vim.log.levels.INFO)
            return
          end

          local fallback_root = primary_root
          if not fallback_root then
            for _, other in ipairs(workspaces) do
              if other.name ~= ws.name and vim.uv.fs_stat(other.root) then
                fallback_root = other.root
                break
              end
            end
          end

          local real_target = vim.uv.fs_realpath(ws.root) or ws.root
          local real_cwd = vim.uv.fs_realpath(vim.uv.cwd() or '') or ''
          local is_current = ws.is_current
            or real_cwd == real_target
            or vim.startswith(real_cwd, real_target .. '/')

          if is_current then
            if not fallback_root then
              vim.notify('No fallback workspace available to switch to', vim.log.levels.ERROR)
              return
            end
            vim.cmd.cd(vim.fn.fnameescape(fallback_root))
          end

          local exec_cwd = fallback_root or jj_root
          local res = M.jj_run(
            { 'workspace', 'forget', ws.name },
            { cwd = exec_cwd, ignore_wc = false }
          )
          if res.code ~= 0 then
            vim.notify(
              'Failed to forget jj workspace: ' .. vim.trim(res.stderr or res.stdout or ''),
              vim.log.levels.ERROR
            )
            return
          end

          if vim.uv.fs_stat(ws.root) then
            local ok, rm_err = pcall(vim.fs.rm, ws.root, { recursive = true, force = true })
            if not ok then
              vim.notify(
                'Forgot workspace, but failed to remove directory: ' .. tostring(rm_err),
                vim.log.levels.WARN
              )
            end
          end

          if is_current and fallback_root then
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(bufnr) then
                local bname = vim.api.nvim_buf_get_name(bufnr)
                local real_bname = bname ~= '' and (vim.uv.fs_realpath(bname) or bname) or ''
                if real_bname == real_target or vim.startswith(real_bname, real_target .. '/') then
                  pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
                end
              end
            end
            vim.cmd.edit(vim.fn.fnameescape(fallback_root))
            vim.api.nvim_exec_autocmds('User', {
              pattern = 'VcsWorkspaceSwitched',
              data = { prev_path = ws.root, path = fallback_root, vcs = 'jj' },
            })
          end

          vim.notify(string.format('Deleted jj workspace: %s (%s)', ws.name, ws.root))
        end)
      end,
    },
  })
end

-- Git worktree wrappers (preserved from previous git.lua behavior)
local function create_git_worktree()
  local fzf = require('fzf-lua')
  local Worktree = require('git-worktree')

  local branches_and_tags = vim.fn.systemlist('git branch -a && git tag')

  fzf.fzf_exec(branches_and_tags, {
    prompt = 'Select branch or tag: ',
    actions = {
      ['default'] = function(selected)
        local branch = selected[1]:gsub('^%s*', ''):gsub('^%*%s*', '')

        local upstream = nil
        if branch:match('^remotes/') then
          upstream = branch:match('^remotes/([^/]+)')
          branch = branch:gsub('^remotes/[^/]+/', '')
        end

        vim.ui.input({ prompt = 'Enter worktree path: ' }, function(path)
          if path and path ~= '' then
            Worktree.create_worktree(path, branch, upstream)
            print('Worktree created: ' .. path)
          else
            print('Worktree creation cancelled')
          end
        end)
      end,
    },
  })
end

local function switch_git_worktree()
  local fzf = require('fzf-lua')
  local Worktree = require('git-worktree')

  local worktrees = vim.fn.systemlist('git worktree list')

  fzf.fzf_exec(worktrees, {
    prompt = 'Select worktree to switch to: ',
    actions = {
      ['default'] = function(selected)
        local path = selected[1]:match('^([^%s]+)')
        Worktree.switch_worktree(path)
        print('Switched to worktree: ' .. path)
      end,
    },
  })
end

local function delete_git_worktree()
  local fzf = require('fzf-lua')
  local Worktree = require('git-worktree')

  local worktrees = vim.fn.systemlist('git worktree list')
  local current_path = vim.fn.getcwd()

  fzf.fzf_exec(worktrees, {
    prompt = 'Select worktree to delete: ',
    actions = {
      ['default'] = function(selected)
        local path = selected[1]:match('^([^%s]+)')
        vim.ui.input(
          { prompt = 'Are you sure you want to delete this worktree? (y/N): ' },
          function(input)
            if input and input:lower() == 'y' then
              local is_current = vim.fn.fnamemodify(path, ':p')
                == vim.fn.fnamemodify(current_path, ':p')

              local actual_git_root
              if is_current then
                actual_git_root = vim.fn.systemlist('git rev-parse --git-common-dir')[1]
                vim.cmd('cd ' .. actual_git_root)
              end

              Worktree.delete_worktree(path, true)
              print('Deleted worktree: ' .. path)

              if is_current then
                print('Moved to actual git root directory: ' .. actual_git_root)
                vim.cmd('bufdo bd')
                vim.cmd('edit ' .. actual_git_root)
              end
            else
              print('Worktree deletion cancelled')
            end
          end
        )
      end,
    },
  })
end

function M.create_workspace()
  local vcs, root = M.root()
  if vcs == 'jj' and root then
    create_jj_workspace(root)
  elseif vcs == 'git' then
    create_git_worktree()
  else
    vim.notify('Not inside a jj or git repository', vim.log.levels.ERROR)
  end
end

function M.switch_workspace()
  local vcs, root = M.root()
  if vcs == 'jj' and root then
    switch_jj_workspace(root)
  elseif vcs == 'git' then
    switch_git_worktree()
  else
    vim.notify('Not inside a jj or git repository', vim.log.levels.ERROR)
  end
end

function M.delete_workspace()
  local vcs, root = M.root()
  if vcs == 'jj' and root then
    delete_jj_workspace(root)
  elseif vcs == 'git' then
    delete_git_worktree()
  else
    vim.notify('Not inside a jj or git repository', vim.log.levels.ERROR)
  end
end

function M.blame_file()
  local vcs = M.root()
  if vcs == 'jj' then
    require('jj.annotate').file()
  elseif vcs == 'git' then
    require('gitsigns').blame()
  else
    vim.notify('Not inside a jj or git repository', vim.log.levels.ERROR)
  end
end

function M.blame_line()
  local vcs = M.root()
  if vcs == 'jj' then
    require('jj.annotate').line()
  elseif vcs == 'git' then
    require('gitsigns').blame_line({ full = true })
  else
    vim.notify('Not inside a jj or git repository', vim.log.levels.ERROR)
  end
end

function M.vcs_status()
  if M.is_jj() then
    require('jj.cmd').status()
  else
    require('fzf-lua').git_status()
  end
end

function M.vcs_commits()
  if M.is_jj() then
    require('jj.cmd').log()
  else
    require('fzf-lua').git_commits()
  end
end

-- Parse a git remote URI (https://, ssh://, git@host:owner/repo.git) matching gitlinker's schema.
---@param uri string
---@return { host: string, port: string|nil, repo: string }|nil
local function parse_remote_uri(uri)
  local allowed = '[_%-%w%.]+'
  local stripped = uri:match('^' .. allowed .. '://(.+)$') or uri:match('^' .. allowed .. '@(.+)$')
  if not stripped then
    return nil
  end
  -- Strip optional user@ after ssh://
  stripped = stripped:gsub('^' .. allowed .. '@', '')
  stripped = stripped:gsub('%.git$', '')

  local host = stripped:match('^(' .. allowed .. ')[:/].+$')
  if not host then
    return nil
  end

  local port = stripped:match('^' .. allowed .. ':([0-9]+)[:/].+$')
  local path_pattern = port and ('^' .. allowed .. ':' .. port .. '[:/](.+)$')
    or ('^' .. allowed .. '[:/](.+)$')
  local repo = stripped:match(path_pattern)
  if not repo or repo == '' then
    return nil
  end
  repo = repo:gsub(' ', '%%20')

  if not uri:match('^https?://') then
    port = nil
  end

  return { host = host, port = port, repo = repo }
end

local function copy_url_with_osc52(url)
  vim.fn.setreg('"', url)
  pcall(function()
    require('osc52').copy(url)
  end)
  vim.notify(url, vim.log.levels.INFO)
end

---@param mode 'n'|'v'
---@return string|nil url
function M.copy_remote_link(mode)
  mode = mode or 'n'

  -- Ensure gitlinker.nvim is loaded so custom host callbacks are registered.
  local gitlinker = require('gitlinker')

  local vcs, root = M.root()
  if vcs ~= 'jj' or not root then
    return gitlinker.get_buf_range_url(mode)
  end

  local buf_path = vim.api.nvim_buf_get_name(0)
  if buf_path == '' then
    vim.notify('Not in a file buffer', vim.log.levels.ERROR)
    return nil
  end

  local rel_path = M.relative_path(root, buf_path)
  if not rel_path or rel_path == '' then
    vim.notify('Current file is outside jj workspace root', vim.log.levels.ERROR)
    return nil
  end

  local range = require('gitlinker.buffer').get_range(mode, true)
  if mode == 'v' then
    local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'nx', false)
  end

  local remote_res = M.jj_run({ 'git', 'remote', 'list' }, { cwd = root })
  if remote_res.code ~= 0 then
    vim.notify(
      'Failed to list jj git remotes: ' .. vim.trim(remote_res.stderr or ''),
      vim.log.levels.ERROR
    )
    return nil
  end

  local remotes = {}
  for line in (remote_res.stdout or ''):gmatch('[^\r\n]+') do
    local name, url = line:match('^(%S+)%s+(%S+)')
    if name and url then
      table.insert(remotes, { name = name, url = url })
    end
  end
  if #remotes == 0 then
    vim.notify('jj repository has no git remote', vim.log.levels.ERROR)
    return nil
  end

  local chosen = remotes[1]
  for _, r in ipairs(remotes) do
    if r.name == 'origin' then
      chosen = r
      break
    end
  end

  local repo_data = parse_remote_uri(chosen.url)
  if not repo_data then
    vim.notify('Failed to parse remote URL: ' .. chosen.url, vim.log.levels.ERROR)
    return nil
  end

  local safe_remote = chosen.name:gsub('"', '\\"')
  local rev_queries = {
    string.format('latest(::@ & ::remote_bookmarks(remote=exact:"%s"))', safe_remote),
    string.format('latest(remote_bookmarks(remote=exact:"%s"))', safe_remote),
    '@',
  }

  local rev = nil
  for _, revset in ipairs(rev_queries) do
    local rev_res = M.jj_run(
      { 'log', '-r', revset, '--no-graph', '-T', 'commit_id ++ "\\n"' },
      { cwd = root }
    )
    if rev_res.code == 0 then
      local candidate = vim.trim(rev_res.stdout or ''):match('^(%x+)')
      if candidate then
        rev = candidate
        break
      end
    end
  end

  if not rev then
    vim.notify('Failed to resolve remote commit for jj repository', vim.log.levels.ERROR)
    return nil
  end

  local exists_res = M.jj_run({ 'file', 'list', '-r', rev, '--', rel_path }, { cwd = root })
  if exists_res.code ~= 0 or vim.trim(exists_res.stdout or '') == '' then
    vim.notify(
      string.format("'%s' does not exist in remote '%s' (%s)", rel_path, chosen.name, rev:sub(1, 8)),
      vim.log.levels.ERROR
    )
    return nil
  end

  local diff_res = M.jj_run(
    { 'diff', '--summary', '--from', rev, '--to', '@', '--', rel_path },
    { cwd = root }
  )
  if (diff_res.code == 0 and vim.trim(diff_res.stdout or '') ~= '') or vim.bo.modified then
    vim.notify(
      string.format("Computed line numbers may be shifted because '%s' has local changes", rel_path),
      vim.log.levels.WARN
    )
  end

  local matching_cb = gitlinker.hosts.get_matching_callback(repo_data.host)
  if not matching_cb then
    return nil
  end

  local url = matching_cb(vim.tbl_extend('force', repo_data, {
    rev = rev,
    file = rel_path,
    lstart = range.lstart,
    lend = range.lend,
  }))
  if not url then
    return nil
  end

  copy_url_with_osc52(url)
  return url
end

return M
