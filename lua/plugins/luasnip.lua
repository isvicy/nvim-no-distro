-- LuaSnip configuration with semicolon prefix for all snippets
-- This prevents snippets from interfering with normal completion
return {
  'L3MON4D3/LuaSnip',
  opts = function(_, opts)
    local ls = require('luasnip')

    -- Add prefix ";" to each snippet using the extend_decorator
    -- This way snippets won't trigger accidentally during normal typing
    -- https://github.com/L3MON4D3/LuaSnip/discussions/895
    local extend_decorator = require('luasnip.util.extend_decorator')

    -- Create trigger transformation function
    local function auto_semicolon(context)
      if type(context) == 'string' then
        return { trig = ';' .. context }
      end
      return vim.tbl_extend('keep', { trig = ';' .. context.trig }, context)
    end

    -- Register and apply decorator properly
    extend_decorator.register(ls.s, {
      arg_indx = 1,
      extend = function(original)
        return auto_semicolon(original)
      end,
    })

    return opts
  end,
}
