local action = require('vfiler/extensions/rename/action')
local core = require('vfiler/libs/core')

local M = {}

M.configs = {
  options = {
    left = '0.5',
  },

  mappings = {
    ['q'] = action.quit,
    ['<ESC>'] = action.quit,
  },

  events = {
    BufWriteCmd = action.execute,
    InsertLeave = action.check,
    CursorMoved = action.check,
  },
}

function M.setup(configs)
  return core.table.merge(M.configs, configs)
end

return M
