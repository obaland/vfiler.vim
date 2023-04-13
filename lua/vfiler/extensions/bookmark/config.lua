local action = require('vfiler/extensions/bookmark/action')
local core = require('vfiler/libs/core')

local M = {}

M.configs = {
  options = {},
  mappings = {
    ['D'] = action.delete,
    ['c'] = action.change_category,
    ['dd'] = action.delete,
    ['h'] = action.close_tree,
    ['j'] = action.loop_cursor_down,
    ['k'] = action.loop_cursor_up,
    ['l'] = action.open_tree,
    ['q'] = action.quit,
    ['r'] = action.rename,
    ['s'] = action.open_by_split,
    ['t'] = action.open_by_tabpage,
    ['v'] = action.open_by_vsplit,
    ['<CR>'] = action.open,
    ['<ESC>'] = action.quit,
  },

  events = {
    vfiler_bookmark = {
      {
        event = 'WinLeave',
        action = action.quit,
      },
    },
  },
}

if core.is_nvim then
  M.configs.options.floating = {
    width = 'auto',
    height = 'auto',
    minwidth = 4,
    minheight = 1,
    relative = true,
  }
else
  M.configs.options.top = 'auto'
end

function M.setup(configs)
  return core.table.merge(M.configs, configs)
end

return M
