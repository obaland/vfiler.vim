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
    vfiler_rename = {
      {
        event = 'WinLeave',
        action = action.quit,
      },
      {
        event = 'BufWriteCmd',
        action = action.execute,
      },
      {
        event = { 'InsertLeave', 'TextChanged' },
        action = action.check,
      },
    },
  },
}

function M.setup(configs)
  return core.table.merge(M.configs, configs)
end

return M
