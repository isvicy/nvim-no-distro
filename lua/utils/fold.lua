---@class FoldUtils
---@field custom_foldtext function Custom fold text with treesitter syntax highlighting
local M = {}

---Fold virtual text helper with treesitter syntax highlighting
---@param result table Result table to append text chunks to
---@param start_text string The starting text of the fold
---@param lnum number Line number
local function fold_virt_text(result, start_text, lnum)
  local text = ''
  local hl
  for i = 1, #start_text do
    local char = start_text:sub(i, i)
    local captured_highlights = vim.treesitter.get_captures_at_pos(0, lnum, i - 1)
    local outmost_highlight = captured_highlights[#captured_highlights]
    if outmost_highlight then
      local new_hl = '@' .. outmost_highlight.capture
      if new_hl ~= hl then
        -- as soon as new hl appears, push substring with current hl to table
        table.insert(result, { text, hl })
        text = ''
        hl = nil
      end
      text = text .. char
      hl = new_hl
    else
      text = text .. char
    end
  end
  table.insert(result, { text, hl })
end

---Custom fold text function with treesitter syntax highlighting
---Source: https://www.reddit.com/r/neovim/comments/1fzn1zt/custom_fold_text_function_with_treesitter_syntax/
---@return table[] Array of {text, highlight_group} tuples for virtual text
M.custom_foldtext = function()
  local start_text = vim.fn.getline(vim.v.foldstart):gsub('\t', string.rep(' ', vim.o.tabstop))
  local nline = vim.v.foldend - vim.v.foldstart
  local result = {}
  fold_virt_text(result, start_text, vim.v.foldstart - 1)
  table.insert(result, { ' ', nil })
  table.insert(result, { '↙ ' .. nline .. ' lines', '@comment.warning' })
  return result
end

return M
