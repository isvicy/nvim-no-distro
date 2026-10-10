local INDENT = '  '

local function trim(s)
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function declaration_rows(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'ssh_config')
  if not ok or not parser then
    return nil, 'ssh_config treesitter parser not available'
  end
  local root = parser:parse()[1]:root()
  if root:has_error() then
    return nil, 'syntax error in buffer, skipped formatting'
  end
  local rows = {}
  for node in root:iter_children() do
    local t = node:type()
    if t == 'host_declaration' or t == 'match_declaration' then
      rows[node:start()] = t
    end
  end
  return rows
end

local function format_lines(lines, decl_rows)
  local tokens = {}
  local in_block = false
  for i, line in ipairs(lines) do
    local text = trim(line)
    local kind
    if text == '' then
      kind = 'blank'
    elseif decl_rows[i - 1] then
      kind = 'decl'
      in_block = true
      if not text:find('"') then
        text = text:gsub('%s+', ' ')
      end
    elseif text:sub(1, 1) == '#' then
      kind = 'comment'
    else
      kind = 'option'
    end
    tokens[#tokens + 1] = { kind = kind, text = text, nested = in_block and kind ~= 'decl' }
  end

  -- Comments directly above a declaration describe it, not the previous block.
  for i, tok in ipairs(tokens) do
    if tok.kind == 'decl' then
      local j = i - 1
      while j >= 1 and tokens[j].kind == 'comment' do
        tokens[j].nested = false
        tokens[j].leads_decl = true
        j = j - 1
      end
    end
  end

  local out = {}
  local pending_blank = false
  local prev_leads = false
  for _, tok in ipairs(tokens) do
    if tok.kind == 'blank' then
      pending_blank = #out > 0
    else
      local starts_group = tok.kind == 'decl' or tok.leads_decl
      if #out > 0 and (pending_blank or (starts_group and not prev_leads)) then
        out[#out + 1] = ''
      end
      out[#out + 1] = (tok.nested and INDENT or '') .. tok.text
      prev_leads = tok.leads_decl or false
      pending_blank = false
    end
  end
  return out
end

local function duplicate_hosts(lines, decl_rows)
  local seen, dups = {}, {}
  local rows = vim.tbl_keys(decl_rows)
  table.sort(rows)
  for _, row in ipairs(rows) do
    if decl_rows[row] == 'host_declaration' then
      local key = trim(lines[row + 1]):gsub('%s+', ' '):lower()
      if seen[key] then
        dups[#dups + 1] = string.format('%s (lines %d, %d)', key, seen[key], row + 1)
      else
        seen[key] = row + 1
      end
    end
  end
  return dups
end

local function format_buffer(bufnr)
  local decl_rows, err = declaration_rows(bufnr)
  if not decl_rows then
    vim.notify('SshFmt: ' .. err, vim.log.levels.WARN)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local formatted = format_lines(lines, decl_rows)
  if not vim.deep_equal(lines, formatted) then
    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
    vim.fn.winrestview(view)
    decl_rows = declaration_rows(bufnr) or {}
  end

  local dups = duplicate_hosts(formatted, decl_rows)
  if #dups > 0 then
    vim.notify('SshFmt: duplicate Host blocks:\n' .. table.concat(dups, '\n'), vim.log.levels.WARN)
  end
end

local bufnr = vim.api.nvim_get_current_buf()

vim.api.nvim_buf_create_user_command(bufnr, 'SshFmt', function()
  format_buffer(bufnr)
end, { desc = 'Format ssh config' })

local group = vim.api.nvim_create_augroup('sshconfig_format', { clear = false })
vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = group,
  buffer = bufnr,
  callback = function()
    format_buffer(bufnr)
  end,
})
