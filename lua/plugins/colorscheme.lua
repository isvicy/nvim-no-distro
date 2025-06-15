local handle = io.popen('od -An -N4 -i /dev/urandom')
if not handle then
  error('Failed to open /dev/urandom')
end
local result = handle:read('*a')
handle:close()
local seed = tonumber(result)
if seed then
  math.randomseed(seed)
end

local pickedTheme
local p = math.random()
if p < 0.1 then
  pickedTheme = 'trundra'
elseif p < 0.6 then
  pickedTheme = 'black-metal'
else
  pickedTheme = 'vesper'
end

pickedTheme = vim.env.NVIM_COLORSCHEME or pickedTheme

local function imPicked(theme)
  if pickedTheme == theme then
    return true
  end
  return false
end

return {
  {
    'datsfilipe/vesper.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      if not imPicked('vesper') then
        return
      end

      require('vesper').setup({
        transparent = false,
      })
      vim.cmd([[set background=dark]])
      vim.cmd([[colorscheme vesper]])
    end,
  },
  {
    'sam4llis/nvim-tundra',
    lazy = false,
    priority = 1000,
    opts = {
      transparent_background = false,
    },
    config = function()
      if not imPicked('trundra') then
        return
      end

      vim.api.nvim_set_hl(0, 'NonText', { fg = '#888888' })
      vim.cmd([[colorscheme tundra]])
    end,
  },
  {
    'metalelf0/black-metal-theme-neovim',
    lazy = false,
    priority = 1000,
    config = function()
      if not imPicked('black-metal') then
        return
      end

      require('black-metal').setup({
        theme = 'bathory',
        variant = 'dark',
      })
      require('black-metal').load()
    end,
  },
}
