-- Git status integration for mini.files
-- Based on: https://gist.github.com/bassamsdata/eec0a3065152226581f8d4244cce9051

local M = {}

M.setup = function()
  local nsMiniFiles = vim.api.nvim_create_namespace('mini_files_git')
  local autocmd = vim.api.nvim_create_autocmd
  local _, MiniFiles = pcall(require, 'mini.files')

  -- Cache for git status
  local gitStatusCache = {}
  local cacheTimeout = 2000

  local function isSymlink(path)
    local stat = vim.loop.fs_lstat(path)
    return stat and stat.type == 'link'
  end

  local function mapSymbols(status, is_symlink)
    local statusMap = {
      [' M'] = { symbol = '', hlGroup = 'MiniDiffSignChange' },
      ['M '] = { symbol = '', hlGroup = 'MiniDiffSignChange' },
      ['MM'] = { symbol = '', hlGroup = 'MiniDiffSignChange' },
      ['A '] = { symbol = '', hlGroup = 'MiniDiffSignAdd' },
      ['AA'] = { symbol = '', hlGroup = 'MiniDiffSignAdd' },
      ['D '] = { symbol = '', hlGroup = 'MiniDiffSignDelete' },
      ['AM'] = { symbol = '', hlGroup = 'MiniDiffSignChange' },
      ['AD'] = { symbol = '', hlGroup = 'MiniDiffSignChange' },
      ['R '] = { symbol = '', hlGroup = 'MiniDiffSignChange' },
      ['U '] = { symbol = '', hlGroup = 'MiniDiffSignChange' },
      ['UU'] = { symbol = '', hlGroup = 'MiniDiffSignAdd' },
      ['UA'] = { symbol = '', hlGroup = 'MiniDiffSignAdd' },
      ['??'] = { symbol = '', hlGroup = 'MiniDiffSignDelete' },
      ['!!'] = { symbol = '', hlGroup = 'MiniDiffSignChange' },
    }

    local result = statusMap[status] or { symbol = '?', hlGroup = 'NonText' }
    local gitSymbol = result.symbol
    local gitHlGroup = result.hlGroup

    local symlinkSymbol = is_symlink and '' or ''

    local combinedSymbol = (symlinkSymbol .. gitSymbol):gsub('^%s+', ''):gsub('%s+$', '')
    local combinedHlGroup = is_symlink and 'MiniDiffSignDelete' or gitHlGroup

    return combinedSymbol, combinedHlGroup
  end

  local function fetchGitStatus(cwd, callback)
    local function on_exit(content)
      if content.code == 0 then
        callback(content.stdout)
      end
    end
    vim.system({ 'git', 'status', '--ignored', '--porcelain' }, { text = true, cwd = cwd }, on_exit)
  end

  local function escapePattern(str)
    if not str then
      return ''
    end
    return (str:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1'))
  end

  local function updateMiniWithGit(buf_id, gitStatusMap)
    vim.schedule(function()
      local nlines = vim.api.nvim_buf_line_count(buf_id)
      local cwd = vim.fs.root(buf_id, '.git')
      local escapedcwd = escapePattern(cwd)

      for i = 1, nlines do
        local entry = MiniFiles.get_fs_entry(buf_id, i)
        if not entry then
          break
        end
        local relativePath = entry.path:gsub('^' .. escapedcwd .. '/', '')
        local status = gitStatusMap[relativePath]

        if status then
          local is_symlink = isSymlink(entry.path)
          local symbol, hlGroup = mapSymbols(status, is_symlink)
          vim.api.nvim_buf_set_extmark(buf_id, nsMiniFiles, i - 1, 0, {
            sign_text = symbol,
            sign_hl_group = hlGroup,
            priority = 2,
          })
        end
      end
    end)
  end

  local function parseGitStatus(content)
    local gitStatusMap = {}
    for line in content:gmatch('[^\r\n]+') do
      local status, filePath = string.match(line, '^(..)%s+(.*)')
      local parts = {}
      for part in filePath:gmatch('[^/]+') do
        table.insert(parts, part)
      end
      local currentKey = ''
      for i, part in ipairs(parts) do
        if i > 1 then
          currentKey = currentKey .. '/' .. part
        else
          currentKey = part
        end
        if i == #parts then
          gitStatusMap[currentKey] = status
        else
          if not gitStatusMap[currentKey] then
            gitStatusMap[currentKey] = status
          end
        end
      end
    end
    return gitStatusMap
  end

  local function updateGitStatus(buf_id)
    local cwd = vim.uv.cwd()
    if not cwd or not vim.fs.root(cwd, '.git') then
      return
    end

    local currentTime = os.time()
    if gitStatusCache[cwd] and currentTime - gitStatusCache[cwd].time < cacheTimeout then
      updateMiniWithGit(buf_id, gitStatusCache[cwd].statusMap)
    else
      fetchGitStatus(cwd, function(content)
        local gitStatusMap = parseGitStatus(content)
        gitStatusCache[cwd] = {
          time = currentTime,
          statusMap = gitStatusMap,
        }
        updateMiniWithGit(buf_id, gitStatusMap)
      end)
    end
  end

  local function clearCache()
    gitStatusCache = {}
  end

  local function augroup(name)
    return vim.api.nvim_create_augroup('MiniFiles_' .. name, { clear = true })
  end

  autocmd('User', {
    group = augroup('start'),
    pattern = 'MiniFilesExplorerOpen',
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      updateGitStatus(bufnr)
    end,
  })

  autocmd('User', {
    group = augroup('close'),
    pattern = 'MiniFilesExplorerClose',
    callback = function()
      clearCache()
    end,
  })

  autocmd('User', {
    group = augroup('update'),
    pattern = 'MiniFilesBufferUpdate',
    callback = function(sii)
      local bufnr = sii.data.buf_id
      local cwd = vim.fn.expand('%:p:h')
      if gitStatusCache[cwd] then
        updateMiniWithGit(bufnr, gitStatusCache[cwd].statusMap)
      end
    end,
  })
end

return M
