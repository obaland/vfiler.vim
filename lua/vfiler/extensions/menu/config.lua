local core = require 'vfiler/core'

local M = {}

M.configs = {
  options = {
    floating = {
      width = 'auto',
      height = 'auto',
      minwidth = 4,
      minheight = 1,
      relative = true,
    },
  },
}

function M.setup(configs)
  return core.table.merge(M.configs, configs)
end

return M
