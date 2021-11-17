local action = require 'vfiler/extensions/rename/action'
local core = require 'vfiler/core'

local M = {}

M.configs = {
  mappings = {
    ['q']     = action.quit,
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
